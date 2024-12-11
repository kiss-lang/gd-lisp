package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import kiss.Stream;
import sys.io.File;

using gd_lisp.lib.GDLispState;

class Generator {
    var state:GDLispStateT;

    public function new() {
        state = {
            readTable: Reader.builtins(),
            startOfLineReadTable: [],
            startOfFileReadTable: [],
            endOfFileReadTable: [],
            identAliases: [],
            syntaxForms: SyntaxForms.builtins(),
            tabLevel: ""
        };

        var readTable = state.readTable;
    }

    function endGenerated(str:String) {
        var longestLine = 0;
        for (line in ('#' + str).split("\n")) {
            if (line.length > longestLine) {
                longestLine = line.length;
            }
        }
        return '\n' + [for (_ in 0...longestLine) "#"].join("") + '\n';
    }

    public function generate(file:String) {
        var code = '';
        
        File.copy(file, '${file}.bak');

        var stream = Stream.fromFile(file);
        
        function findNextGDLisp() {
            code += switch(stream.takeUntil('#(', true)) {
                case Some(gdscript):
                    gdscript;
                case None:
                    "";
            };
            state.tabLevel = stream.currentTab();
            stream.dropStringIf('#');
        }

        findNextGDLisp();
        Reader.readAndProcessCC(stream, state, (nextExp, str, cc) -> {
            code += '#${str}\n';
            code += convert(state, nextExp);
            stream.dropUntil('#');
            stream.dropWhileOneOf(['\n', '#']);
            code += state.tabbed(endGenerated(str));

            findNextGDLisp();
            cc();
        });

        File.saveContent(file, code);
        return code;
    }

    public static function convert(g: GDLispStateT, exp:ReaderExp):String {
        var globalTab = g.tabLevel;
        g.tabLevel = "";

        var code = switch (exp.def) {
            case CallExp({def:Symbol(name)}, args) if (g.syntaxForms.exists(name)):
                g.syntaxForms[name](exp, args.copy(), g);
            default:
                "";
        };

        g.tabLevel = globalTab;
        return g.tabbed(code);
    }
}

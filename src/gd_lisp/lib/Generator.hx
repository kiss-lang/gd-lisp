package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import kiss.Stream;
import sys.io.File;

using kiss.ExpBuilder;
using gd_lisp.lib.Generator;
using gd_lisp.lib.GDLispState;

class Generator {
    var state:GDLispStateT;

    public function new() {
        state = GDLispState.defaultState();

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
            var converted = state.convert(nextExp);
            code += converted;
            stream.dropUntil('#');
            stream.dropWhileOneOf(['\n', '#']);
            code += state.tabbed(endGenerated(str + '\n' + converted));

            findNextGDLisp();
            cc();
        });

        File.saveContent(file, code);
        return code;
    }

    public static function convert(g: GDLispStateT, exp:ReaderExp):String {
        var globalTab = g.tabLevel;
        g.tabLevel = "";

        var b = exp.expBuilder();
        var code = switch (exp.def) {
            case CallExp({def:Symbol(name)}, args) if (g.syntaxForms.exists(name)):
                g.syntaxForms[name](exp, args.copy(), g);
            case CallExp({def:Symbol(name)}, args) if (g.callAliases.exists(name)):
                g.convert(b.call(b.expFromDef(g.callAliases[name]), args));
            case CallExp({def:Symbol(name)}, args):
                '$name(${[for(arg in args) g.convert(arg)].join(", ")})';
            case Symbol(name) if (g.identAliases.exists(name)):
                g.convert(b.expFromDef(g.identAliases[name]));
            case Symbol(name):
                name;
            default:
                "";
        };

        g.tabLevel = globalTab;
        return g.tabbed(code);
    }
}

package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import kiss.Stream;
import sys.io.File;

class Generator {
    var state:GDLispState;

    public function new() {
        state = {
            readTable: Reader.builtins(),
            startOfLineReadTable: [],
            startOfFileReadTable: [],
            endOfFileReadTable: [],
            identAliases: [],
            syntaxForms: SyntaxForms.builtins()
        };
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
            stream.dropStringIf('#');
        }
        findNextGDLisp();
        Reader.readAndProcessCC(stream, state, (nextExp, str, cc) -> {
            code += '#${str}\n';
            code += convert(nextExp);
            stream.dropUntil('#');
            stream.dropWhileOneOf(['\n', '#']);
            code += endGenerated(str);

            findNextGDLisp();
            cc();
        });

        File.saveContent(file, code);
        return code;
    }

    public function convert(exp:ReaderExp):String {
        return 'bla';
    }
}

package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import kiss.Stream;
import sys.io.File;

using StringTools;
using kiss.ExpBuilder;
using gd_lisp.lib.Generator;
using gd_lisp.lib.GDLispState;

class Generator {
    var state:GDLispStateT;

    public function new() {
        state = GDLispState.defaultState();
    }

    function endGenerated(str:String) {
        var longestLine = 0;
        for (line in ('#' + str).split("\n")) {
            if (line.length > longestLine) {
                longestLine = line.length;
            }
        }
        return [for (_ in 0...longestLine) "#"].join("");
    }

    public function generate(file:String) {
        var code = '';
        
        File.copy(file, '${file}.bak');

        var stream = Stream.fromFile(file);
        
        function findNextGDLisp() {
            stream.linePrefix = '';
            code += switch(stream.takeUntil('#(', true)) {
                case Some(gdscript):
                    gdscript;
                case None:
                    "";
            };
            state.tabLevel = stream.currentTab();
            stream.linePrefix = state.tabLevel + "#";
            stream.dropStringIf('#');
        }

        findNextGDLisp();
        Reader.readAndProcessCC(stream, state, (nextExp, str, cc) -> {
            code += '#${str}\n';
            var converted = state.convert(nextExp);
            code += converted;
            
            var terminators = ['###', '#('];
            var gdlispExisting = stream.takeUntilOneOf(terminators, true);
            switch (stream.takeOneOf(terminators)) {
                // EOF! Keep the existing stuff
                case None:
                // Another gdlisp block!
                case Some('#('):
                    stream.putBackString('${stream.currentTab()}#(');
                // End of generated block!
                case Some('###'):
                    stream.dropUntil('\n');
                    stream.dropString('\n');
                    gdlispExisting = None;
                default:
            };

            code += state.tabbed(endGenerated(str + '\n' + converted));
            code += '\n';

            switch(gdlispExisting) {
                case Some(gdlisp):
                    code += gdlisp.rtrim() + '\n';
                default:
            }

            findNextGDLisp();
            cc();
        });

        File.saveContent(file, code);
        return code;
    }

    public static var argNum(default, null) = 0;
    public static function captureArgs(g:GDLispStateT, args:Array<ReaderExp>) {
        var code = '';

        var funcArgs = [];
        for (arg in args) {
            // Try converting without a context. If it comes back as a one-liner, pass that directly to the args
            g.pushContext(None);
            var withoutContext = g.convert(arg, true);
            if (withoutContext.rtrim().split('\n').length == 1) {
                funcArgs.push(withoutContext);
            }
            // If the expression can't be passed inline, capture it
            else {
                funcArgs.push('_arg${argNum}');
                g.pushContext(Capture('_arg${argNum++}'));
                code += g.convert(arg);
            }
        }
        g.capturedArgs.push(funcArgs);
        return code;
    }

    public static function convert(g: GDLispStateT, exp:ReaderExp, _inline = false):String {
        var globalTab = g.tabLevel;
        g.tabLevel = "";

        var b = exp.expBuilder();

        var code = "";
        switch (exp.def) {
            // Special expressions
            case CallExp({def:Symbol(name)}, args) if (g.syntaxForms.exists(name)):
                code += g.syntaxForms[name](exp, args.copy(), g);
            case CallExp({def:Symbol(name)}, args) if (g.callAliases.exists(name)):
                code += g.convert(b.call(b.expFromDef(g.callAliases[name]), args));
            case Symbol(name) if (g.identAliases.exists(name)):
                code += g.convert(b.expFromDef(g.identAliases[name]));
            default:
                // Basic expressions
                switch (exp.def) {
                    case CallExp({def:Symbol(name)}, args):
                        code += g.captureArgs(args);
                        code += g.popContextPrefix() + '$name(${g.popCapturedArgs().join(", ")})';
                    case Symbol(name):
                        code += g.popContextPrefix() + name;
                    default:
                        throw 'expression ${Reader.toString(exp.def)} cannot be converted!';
                }
        };

        g.tabLevel = globalTab;
        return if (_inline) {
            code.rtrim();
        } else {
            g.tabbed(code).rtrim() + '\n';
        }
    }
}

package gd_lisp.lib;

#if macro
import haxe.macro.Expr;
#end
import sys.io.File;

import kiss.Prelude;
import kiss.ReaderExp;
import gd_lisp.lib.GDLispState;
using StringTools;
using kiss.ExpBuilder;
using gd_lisp.lib.GDLispState;
using gd_lisp.lib.Generator;

// Syntax forms convert Kiss reader expressions into GDScript
typedef SyntaxFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, g: GDLispStateT) -> String;

class SyntaxForms {
    static macro function syntaxForm(name:String, body:Expr) {
        return macro {
            function $name (wholeExp:ReaderExp, args:Array<ReaderExp>, g: GDLispStateT) {
                return $body;
            }
            map[$v{name}] = $i{name};
        };
    }

    // TODO add GENERATED before generated, change it to MODIFIED when the gdscript is directly modified
    // and don't regenerated MODIFIED gdscript

    public static function builtins():Map<String,SyntaxFunction> {
        var map:Map<String,SyntaxFunction> = [];

        // TODO this needs to be relative or compiled in
        syntaxForm("prelude", File.getContent("src/gd_lisp/lib/Prelude.gd"));

        // Convert an array of expressions. Only pass the current context to the last expression,
        // which will pop it
        syntaxForm("begin", {
            var context = g.context();
            var code = '';
            var lastExp = args.pop();
            for (exp in args) {
                g.pushContext(None);
                code += g.convert(exp).rtrim() + '\n';
            }
            code += g.convert(lastExp).rtrim() + '\n';
            return code;
        });

        // Return an expression
        syntaxForm("_return", {
            g.pushContext(Return);
            var code = g.convert(args[0]);
            g.tryPopContext();
            code;
        });

        syntaxForm("_var", {
            var code = '';
            g.pushContext(Capture(Prelude.symbolNameValue(args[0])));
            code += g.convert(args[1]);

            code;
        });

        var setNum = 0;
        syntaxForm("set", {
            var code = "";
            code += g.captureArgs([args[1]]);
            if (code.length > 0) code += '\n';
            code += '${Prelude.symbolNameValue(args[0])} = ${g.popCapturedArgs()[0]}';
            code;
        });

        var letNum = 0;
        syntaxForm("let", {
            var b = wholeExp.expBuilder();
            var bindings = Prelude.groups(Prelude.bindingList(args[0], "let"), 2);
            var code = '';
            code += 'var _let${letNum} = func(${[for (binding in bindings) Prelude.symbolNameValue(binding[0])].join(", ")}):\n';
            g.tab();

            switch (g.context()) {
                case Capture(_):
                    g.pushContext(Return);
                default:
            }

            code += g.convert(b.begin(args.slice(1)));
            g.untab();
            code = code.rtrim();
            code += '\n';

            code += g.convert(b.callSymbol('_let${letNum++}.call', [for (binding in bindings) binding[1]]));
            g.tryPopContext();
            code;
        });

        syntaxForm("func", {
            var b = wholeExp.expBuilder();
            var argListIdx = 0;
            var name = switch(args[0].def) {
                case Symbol(name):
                    ++argListIdx;
                    '${name} ';
                default: '';
            };
            var funcArgs = Prelude.argList(args[argListIdx], 'func');
            var bodyExps = args.slice(argListIdx+1);
            var code = g.popContextPrefix() + 'func ${name}(${[for (arg in funcArgs) Prelude.symbolNameValue(arg)].join(", ")}):\n';
            g.tab();
            code += g.convert(b.begin(bodyExps));
            return code;
        });

        function arithmetic(op:String, args:Array<ReaderExp>, g:GDLispStateT, defaultFirst:ReaderExpDef) {
            if (args.length == 1) {
                var b = args[0].expBuilder();
                args.unshift(b.expFromDef(defaultFirst));
            } else if (args.length == 0) {
                throw 'arithmetic with no arguments';
            }
            var code = g.captureArgs(args);
            if (code.length > 0) code += '\n';
            return '${code}${g.popContextPrefix()}(' + g.popCapturedArgs().join(' ${op} ') + ')';
        }

        syntaxForm("plus", {
            arithmetic("+", args, g, Symbol('0'));
        });

        syntaxForm("minus", {
            arithmetic("-", args, g, Symbol('0'));
        });
        
        syntaxForm("divide", {
            arithmetic("/", args, g, Symbol('1'));
        });
        
        syntaxForm("times", {
            arithmetic("*", args, g, Symbol('1'));
        });

        function comparison(op:String, args:Array<ReaderExp>, g:GDLispStateT) {
            var code = g.captureArgs(args);
            if (code.length > 0) code += '\n';
            var pairs = Prelude.pairs(g.popCapturedArgs());
            return '${code}${g.popContextPrefix()}(' + [for (pair in pairs) pair[0] + op + pair[1]].join(' && ') + ')';
        }

        syntaxForm("lesser", {
            comparison("<", args, g);
        });
        syntaxForm("lesserEquals", {
            comparison("<=", args, g);
        });
        syntaxForm("equals", {
            comparison("==", args, g);
        });
        syntaxForm("greaterEquals", {
            comparison(">=", args, g);
        });
        syntaxForm("greater", {
            comparison(">", args, g);
        });

        var andNum = 0;
        var orNum = 0;
        function logic(op:String, keyword:String, args:Array<ReaderExp>, defaultValue:Bool, g:GDLispStateT) {
            var captureVar = '_${keyword}';
            if (keyword == 'and') captureVar += andNum++;
            else captureVar += orNum++;
            var code = 'var ${captureVar} = func():\n';
            g.tab();
            var evaluated = '';
            for (arg in args) {
                code += g.captureArgs([arg], true);
                evaluated = g.popCapturedArgs()[0];
                code += '${g.tabLevel}if truthy(${evaluated}) != ${defaultValue}:\n${g.tabLevel}\treturn ${evaluated}\n';
            }
            code += '${g.tabLevel}return ${evaluated}\n';
            g.untab();
            code += g.popContextPrefix() + '${captureVar}.call()';
            return code;
        }

        syntaxForm("and", {
            logic("&&", "and", args, true, g);
        });
        syntaxForm("or", {
            logic("||", "or", args, false, g);
        });

        return map;
    }
}
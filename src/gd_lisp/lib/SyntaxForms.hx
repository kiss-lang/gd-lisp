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
        // and pop the current context
        syntaxForm("begin", {
            var context = g.context();
            var code = '';
            var lastExp = args.pop();
            for (exp in args) {
                g.pushContext(None);
                code += g.convert(exp) + '\n';
            }
            code += g.convert(lastExp) + '\n';
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
            g.pushContext(Capture('_set_val${setNum}'));
            code += g.convert(args[1]);
            g.tryPopContext();
            code += Prelude.symbolNameValue(args[0]) + ' = _set_val${setNum++}';

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

        function arithmetic(op:String, args:Array<ReaderExp>, g:GDLispStateT, defaultFirst:ReaderExpDef) {
            if (args.length == 1) {
                var b = args[0].expBuilder();
                args.unshift(b.expFromDef(defaultFirst));
            } else if (args.length == 0) {
                throw 'arithmetic with no arguments';
            }
            var code = g.captureArgs(args);
            return '${code}\n${g.popContextPrefix()}(' + g.popCapturedArgs().join(' ${op} ') + ')';
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
        return map;
    }
}
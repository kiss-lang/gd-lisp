package gd_lisp.lib;

#if macro
import haxe.macro.Expr;
#end
import sys.io.File;

import kiss.Prelude;
import kiss.ReaderExp;
import gd_lisp.lib.GDLispState;
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

        // TODO this needs to be relative
        syntaxForm("prelude", File.getContent("src/gd_lisp/lib/Prelude.gd"));

        var letNum = 0;
        syntaxForm("begin", {
            var code = '';
            var lastExp = args.pop(); 
            for (exp in args) {
                code += g.convert(exp) + '\n';
            }
            code += 'return ' + g.convert(lastExp);
            return code;
        });

        syntaxForm("let", {
            var b = wholeExp.expBuilder();
            var bindings = Prelude.groups(Prelude.bindingList(args[0], "let"), 2);

            var code = 'func _let${letNum++}(${[for (binding in bindings) Prelude.symbolNameValue(binding[0])].join(", ")}):\n';
            g.tab();
            code += g.convert(b.begin(args.slice(1)));
            code;
        });

        function arithmetic(op:String, args:Array<ReaderExp>, g:GDLispStateT) {
            return args.map(g.convert).join(' ${op} ');
        }

        syntaxForm("plus", {
            arithmetic("+", args, g);
        });

        return map;
    }
}
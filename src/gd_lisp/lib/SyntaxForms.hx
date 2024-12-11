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

        syntaxForm("_return", {
            var code = g.convert(args[0]);
            var lines = code.split("\n");
            var lastLine = lines.pop();
            var lastLineNoTab = lastLine.ltrim();
            var lastLineTab = lastLine.substr(0, lastLine.length - lastLineNoTab.length);
            lines.join("\n") + '\n${lastLineTab}return ' + lastLineNoTab;
        });

        // This seems the same as _return but it deals with expressions, not the finished text, and for some reason that matters
        syntaxForm("begin", {
            var code = '';
            var lastExp = args.pop(); 
            for (exp in args) {
                code += g.convert(exp) + '\n';
            }
            code += 'return ' + g.convert(lastExp);
            return code;
        });

        var letNum = 0;
        syntaxForm("let", {
            var b = wholeExp.expBuilder();
            var bindings = Prelude.groups(Prelude.bindingList(args[0], "let"), 2);

            var code = 'func _let${letNum}(${[for (binding in bindings) Prelude.symbolNameValue(binding[0])].join(", ")}):\n';
            g.tab();
            code += g.convert(b.begin(args.slice(1)));
            g.untab();
            code += '\n';
            code += '_let${letNum++}(${[for (binding in bindings) g.convert(binding[1], true)].join(", ")})';
            code;
        });

        function arithmetic(op:String, args:Array<ReaderExp>, g:GDLispStateT, defaultFirst:ReaderExpDef) {
            if (args.length == 1) {
                var b = args[0].expBuilder();
                args.unshift(b.expFromDef(defaultFirst));
            } else if (args.length == 0) {
                throw 'arithmetic wtih no arguments';
            }
            return '(' + args.map(g.convert.bind(_, true)).join(' ${op} ') + ')';
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
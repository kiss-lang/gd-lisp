package gd_lisp.lib;

#if macro
import haxe.macro.Expr;
#end

import kiss.ReaderExp;
import gd_lisp.lib.GDLispState;
using gd_lisp.lib.GDLispState;

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

    public static function builtins():Map<String,SyntaxFunction> {
        var map:Map<String,SyntaxFunction> = [];

        var letNum = 0;
        syntaxForm("let", {
            var code = 'func _let${letNum++}():\n';
            g.tab();
            code += g.tabbed('pass');
            code;
        });

        return map;
    }
}
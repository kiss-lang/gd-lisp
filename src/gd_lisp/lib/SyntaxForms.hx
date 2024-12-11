package gd_lisp.lib;

#if macro
import haxe.macro.Expr;
#end

import kiss.ReaderExp;

// Syntax forms convert Kiss reader expressions into GDScript
typedef SyntaxFunction = (wholeExp:ReaderExp, args:Array<ReaderExp>, g: GDLispState) -> String;

class SyntaxForms {
    static macro function syntaxForm(name:String, body:Expr) {
        return macro {
            function $name (wholeExp:ReaderExp, args:Array<ReaderExp>, g: GDLispState) {
                return $body;
            }
            map[$v{name}] = $i{name};
        };
    }

    public static function builtins():Map<String,SyntaxFunction> {
        var map:Map<String,SyntaxFunction> = [];

        var letNum = 0;
        syntaxForm("let", {
            'func _let${letNum++}()';
        });

        return map;
    }
}
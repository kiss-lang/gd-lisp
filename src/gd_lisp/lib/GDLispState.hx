package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import gd_lisp.lib.SyntaxForms;

typedef GDLispStateT = {
    > HasReadTables,
    tabLevel:String,
    callAliases:Map<String,ReaderExpDef>,
    syntaxForms:Map<String,SyntaxFunction>
};

class GDLispState {
    public static function defaultState():GDLispStateT {
        return {
            readTable: Reader.builtins(),
            startOfLineReadTable: [],
            startOfFileReadTable: [],
            endOfFileReadTable: [],
            identAliases: [],
            callAliases: [
                "print" => Symbol("_gdprint"),
                "+" => Symbol("plus"),
                "-" => Symbol("minus"),
                "/" => Symbol("divide"),
                "*" => Symbol("times"),
                "return" => Symbol("_return")
            ],
            syntaxForms: SyntaxForms.builtins(),
            tabLevel: ""
        };
    }

    public static function tab(g:GDLispStateT) {
        g.tabLevel += '\t';
    }
    public static function untab(g:GDLispStateT) {
        g.tabLevel = g.tabLevel.substr(0, g.tabLevel.length - 1);
    }
    public static function tabbed(g:GDLispStateT, code:String) {
        return [for (line in code.split("\n")) g.tabLevel + line].join("\n");
    }
}
package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import gd_lisp.lib.SyntaxForms;

typedef GDLispStateT = {
    > HasReadTables,
    tabLevel:String,
    callAliases:Map<String,ReaderExpDef>,
    syntaxForms:Map<String,SyntaxFunction>,
    contextStack:kiss.List<Context>
};

enum Context {
    None;
    Return;
}

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
                "return" => Symbol("_return"),
                "assertEq" => Symbol("assertEquals"),
            ],
            syntaxForms: SyntaxForms.builtins(),
            tabLevel: "",
            contextStack: [ None ]
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

    public static function context(g:GDLispStateT) {
        return g.contextStack[-1];
    }

    public static function pushContext(g:GDLispStateT, context:Context) {
        g.contextStack.push(context);
    }

    public static function tryPopContext(g:GDLispStateT) {
        return if (g.contextStack.length > 0) {
            g.contextStack.pop();
        } else {
            None;
        };
    }
}
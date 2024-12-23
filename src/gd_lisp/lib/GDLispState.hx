package gd_lisp.lib;

import kiss.Reader;
import kiss.ReaderExp;
import kiss.Stream;
import gd_lisp.lib.SyntaxForms;
using gd_lisp.lib.GDLispState;

typedef GDLispStateT = {
    > HasReadTables,
    tabLevel:String,
    callAliases:Map<String,ReaderExpDef>,
    syntaxForms:Map<String,SyntaxFunction>,
    contextStack:Array<Context>,
    capturedArgs:Array<Array<String>>
};

enum Context {
    None;
    Return;
    Capture(varName:String);
    Set(varName:String);
}

class GDLispState {
    public static function defaultState():GDLispStateT {

        var readTable = Reader.builtins();

        readTable['#'] = (stream:Stream, k:HasReadTables) -> null;

        return {
            readTable: readTable,
            startOfLineReadTable: [],
            startOfFileReadTable: [],
            endOfFileReadTable: [],
            identAliases: [],
            callAliases: [
                "print" => Symbol("_gdprint"),
                "+" => Symbol("plus"),
                "+=" => Symbol("plusEquals"),
                "-" => Symbol("minus"),
                "-=" => Symbol("minusEquals"),
                "/" => Symbol("divide"),
                "/=" => Symbol("divideEquals"),
                "*" => Symbol("times"),
                "*=" => Symbol("timesEquals"),
                "<" => Symbol("lesser"),
                "<=" => Symbol("lesserEquals"),
                "=" => Symbol("equals"),
                ">=" => Symbol("greaterEquals"),
                ">" => Symbol("greater"),
                "return" => Symbol("_return"),
                "assertEq" => Symbol("assertEquals"),
                "var" => Symbol("_var"),
                "not" => Symbol("_not"),
                "if" => Symbol("_if")
            ],
            syntaxForms: SyntaxForms.builtins(),
            tabLevel: "",
            contextStack: [ None ],
            capturedArgs: []
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
        trace(g.contextStack);
        return g.contextStack[g.contextStack.length - 1];
    }

    public static function pushContext(g:GDLispStateT, context:Context) {
        g.contextStack.push(context);
    }

    public static function tryPopContext(g:GDLispStateT) {
        return if (g.contextStack.length > 1) {
            trace(g.context());
            g.contextStack.pop();
        } else {
            None;
        };
    }

    public static function popContextPrefix(g:GDLispStateT) {
        return switch(g.tryPopContext()) {
            case Return:
                'return ';
            case Capture(varName):
                'var $varName = ';
            case Set(varName):
                '$varName = ';
            default:
                '';
        };
    }

    public static function popCapturedArgs(g:GDLispStateT) {
        return g.capturedArgs.pop();
    }
}
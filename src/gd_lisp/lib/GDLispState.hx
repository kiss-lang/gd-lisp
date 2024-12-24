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
    Append(arrName:String);
    DictSet(dictName:String);
}

class GDLispState {
    public static function defaultState():GDLispStateT {

        var readTable = Reader.builtins({
            keepBraceExps: true
        });

        // Multiline expressions will have # at the start of every line
        readTable['#'] = (stream:Stream, k:HasReadTables) -> null;
        // @ inserts a breakpoint
        readTable['@'] = (stream:Stream, k:HasReadTables) -> Symbol("breakpoint");
        // $ lets gdscript handle its own $ syntax
        readTable['$'] = (stream:Stream, k:HasReadTables) -> {
            var str = "$";
            str += switch (stream.peekChars(1)) {
                // if the path literal starts with " or ', take the rest of it
                case Some(quote) if (['"', "'"].contains(quote)):
                    stream.dropString(quote);
                    quote + stream.expect('', () -> stream.takeUntilAndDrop(quote)) + quote;
                default:
                    stream.expect('', () ->stream.takeUntilOneOf(Reader.whitespace));
            };
            RawHaxeBlock(str);
        };
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
                "if" => Symbol("_if"),
                "for" => Symbol("_for"),
                "while" => Symbol("_while")
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
        return g.contextStack[g.contextStack.length - 1];
    }

    public static function pushContext(g:GDLispStateT, context:Context) {
        g.contextStack.push(context);
    }

    public static function tryPopContext(g:GDLispStateT) {
        return if (g.contextStack.length > 1) {
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
            case Append(arrName):
                '${arrName}.append(';
            case DictSet(dictName):
                'dictSet(${dictName}, ';
            default:
                '';
        };
    }

    public static function contextSuffix(g:GDLispStateT) {
        return switch (g.context()) {
            case Append(_) | DictSet(_):
                ')';
            default:
                '';
        }
    }

    public static function inContext(g:GDLispStateT, codeLine:String) {
        var suffix = g.contextSuffix();
        return '${g.popContextPrefix()}${codeLine}${suffix}';
    }

    public static function popCapturedArgs(g:GDLispStateT) {
        return g.capturedArgs.pop();
    }
}
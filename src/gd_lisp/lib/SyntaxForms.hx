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

enum IfElseBranch {
    If(cond:ReaderExp);
    Elif(cond:ReaderExp);
    Else;
}

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

        map["func"] = func.bind(_, _, _, false);
        map["lambda"] = func.bind(_, _, _, true);

        function arithmetic(op:String, args:Array<ReaderExp>, g:GDLispStateT, defaultFirst:ReaderExpDef) {
            if (args.length == 1) {
                var b = args[0].expBuilder();
                args.unshift(b.expFromDef(defaultFirst));
            } else if (args.length == 0) {
                throw 'arithmetic with no arguments';
            }
            var code = g.captureArgs(args);
            if (code.length > 0) code += '\n';
            code += g.inContext('(' + g.popCapturedArgs().join(' ${op} ') + ')');
            return code;
        }

        var rhsNum = 0;
        function arithmeticEquals(op:String, rhsOp:String, args:Array<ReaderExp>, g:GDLispStateT) {
            if (args.length < 2) {
                throw 'not enough operands for ${op}=';
            }
            var b = args[1].expBuilder();
            var code = g.captureArgs([b.callSymbol(rhsOp, args.slice(1))]);
            if (code.length > 0) code += '\n';
            code += g.inContext('${g.convert(args[0]).rtrim()} ${op}= ${g.popCapturedArgs()[0]}');
            return code;
        }

        syntaxForm("plus", {
            arithmetic("+", args, g, Symbol('0'));
        });
        syntaxForm("plusEquals", {
            arithmeticEquals("+", "+", args, g);
        });

        syntaxForm("minus", {
            arithmetic("-", args, g, Symbol('0'));
        });
        syntaxForm("minusEquals", {
            arithmeticEquals("-", "+", args, g);
        });
        
        syntaxForm("divide", {
            arithmetic("/", args, g, Symbol('1'));
        });
        syntaxForm("divideEquals", {
            arithmeticEquals("/", "*", args, g);
        });
        
        syntaxForm("times", {
            arithmetic("*", args, g, Symbol('1'));
        });
        syntaxForm("timesEquals", {
            arithmeticEquals("*", "*", args, g);
        });

        function comparison(op:String, args:Array<ReaderExp>, g:GDLispStateT) {
            var code = g.captureArgs(args);
            if (code.length > 0) code += '\n';
            var pairs = Prelude.pairs(g.popCapturedArgs());
            code += g.inContext('(' + [for (pair in pairs) pair[0] + op + pair[1]].join(' && ') + ')');
            return code;
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

        var alwaysBool = [
            'not',
            '<',
            '<=',
            '=',
            '>=',
            '>'
        ];
        function mustWrapTruthy(exp:ReaderExp) {
            return switch(exp.def) {
                case CallExp({def: Symbol(name)}, _) if (alwaysBool.contains(name)):
                    false;
                case Symbol("true" | "false"):
                    false;
                default:
                    true;
            };
        }

        // Each branch passed to this function is an array of [<condition> <then...>]
        function ifElse(branches:Array<Array<ReaderExp>>, g:GDLispStateT) {
            var code = '';
            var first = branches.shift();
            var last = branches.pop();

            // Check if the last one is an else branch
            if (last != null) {
                switch (last[0]) {
                    case {def:Symbol("else" | "true")}:
                    default:
                        branches.push(last);
                        last = null;
                }
            }

            function handleCondition(condition:ReaderExp, keyword:String) {
                var wrap = mustWrapTruthy(condition);
                var cArgs = g.captureArgs([condition]);
                if (cArgs.length > 0) {
                    code += cArgs.rtrim() + '\n';
                }
                code += '${keyword} ${if (wrap) "truthy(" else ""}${g.popCapturedArgs()[0]}${if (wrap) ")" else "")}:\n';
            }

            var innerContext = switch(g.context()) {
                case Capture(varName):
                    code += 'var ${varName} = null\n';    
                    Set(varName);
                default:
                    g.context();
            };

            function handleIfElseBranch(which:IfElseBranch, body:Array<ReaderExp>) {
                var b = body[0].expBuilder();
                switch (which) {
                    case If(condition):
                        handleCondition(condition, 'if');
                    case Elif(condition):
                        handleCondition(condition, 'elif');
                    case Else:
                        code += 'else:\n';
                }
                g.tab();
                // Pass the context to the branches
                g.pushContext(innerContext);
                code += g.convert(b.begin(body));
                g.untab();
            }
            
            handleIfElseBranch(If(first[0]), first.slice(1));
            for (branch in branches) {
                handleIfElseBranch(Elif(branch[0]), branch.slice(1));
            }
            if (last != null) {
                handleIfElseBranch(Else, last.slice(1));
            }

            g.tryPopContext();
            return code;
        }

        syntaxForm("_if", {
            var condition = args[0];
            var then = args[1];
            var branches = [[condition, then]]; 
            if (args.length > 2) {
                var b = args[2].expBuilder();
                branches.push([b.symbol('else'), args[2]]);
            }

            ifElse(branches, g);
        });

        syntaxForm("when", {
            ifElse([args], g);
        });
        syntaxForm("unless", {
            var b = wholeExp.expBuilder();
            ifElse([[b.not(args[0])].concat(args.slice(1))], g);
        });

        syntaxForm("cond", {
            var branches = [for (arg in args) {
                switch(arg.def) {
                    case CallExp(condition, body):
                        [condition].concat(body);
                    default:
                        throw 'bad cond args';
                }
            }];
            ifElse(branches, g);
        });

        map["_for"] = _for.bind(_, _, _, true);

        var whileCondNum = 0;
        syntaxForm("_while", {
            var code = '';
            var cond = args[0];
            var b = cond.expBuilder();
            var body = args.slice(1);
            if (mustWrapTruthy(cond)) {
                cond = b.callSymbol("truthy", [cond]);
            }

            var convertedCond = g.convert(cond).rtrim();
            // Multiline conditions need to expand their arguments each time
            if (convertedCond.split("\n").length > 1) {
                var condLambda = '_whileCond${whileCondNum++}';
                code += g.convert(
                    b.callSymbol("var", [b.symbol(condLambda),
                        b.callSymbol("lambda", [b.list([]), cond])]));
                code += 'while ${condLambda}.call():\n';
            } else {
                code += 'while ${convertedCond}:\n';
            }
            g.tab();
            code += g.convert(body[0].expBuilder().begin(body));
            code;
        });

        return map;
    }

    static var collectionNum = 0;
    public static function _for(wholeExp:ReaderExp, args:Array<ReaderExp>, g:GDLispStateT, arr:Bool) {
        // Get the name for each element
        g.pushContext(None);
        var elemName = g.convert(args[0]).rtrim();
        // Capture the collection to iterate
        var code = g.captureArgs([args[1]]);
        if (code.length > 0) code += '\n';
        var containerExp = g.popCapturedArgs()[0];

        var collecting = null;
        switch(g.context()) {
            case None:
            default:
                collecting = '_collection${collectionNum++}';
                code += 'var ${collecting} =';
                if (arr) {
                    code += '[]';
                } else {
                    code += '{}';
                }
                code += '\n';
        }
        if (collecting != null) {
            g.pushContext(if(arr) {
                Append(collecting);
            } else {
                DictSet(collecting);
            });
        } else {
            g.pushContext(None);
        }
        g.tab();
        var b = args[2].expBuilder();
        var bodyCode = g.convert(b.begin(args.slice(2)));
        g.untab();
        code += 'for ${elemName} in ${containerExp}:\n';
        code += bodyCode;
        if (collecting != null) {
            code += g.inContext(collecting);
        }
        return code;
    }

    static function func(wholeExp:ReaderExp, args:Array<ReaderExp>, g:GDLispStateT, returnLast:Bool) {
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
        var suffix = g.contextSuffix();
        var code = g.popContextPrefix() + 'func ${name}(${[for (arg in funcArgs) Prelude.symbolNameValue(arg)].join(", ")}):\n';
        g.tab();
        var body = b.begin(bodyExps);
        if (returnLast) {
            body = b.callSymbol("return", [body]);
        }
        code += g.convert(body) + suffix;
        return code;
    }
}
package gd_lisp.lib;

import kiss.Reader;
import gd_lisp.lib.SyntaxForms;

typedef GDLispStateT = {
    > HasReadTables,
    tabLevel:String,
    syntaxForms:Map<String,SyntaxFunction> 
};

class GDLispState {
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
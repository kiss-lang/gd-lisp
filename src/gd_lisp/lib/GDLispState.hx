package gd_lisp.lib;

import kiss.Reader;
import gd_lisp.lib.SyntaxForms;

typedef GDLispState = {
    > HasReadTables,
    syntaxForms:Map<String,SyntaxFunction> 
};

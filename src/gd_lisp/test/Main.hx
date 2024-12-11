package gd_lisp.test;

import gd_lisp.lib.Generator;

class Main {
    static function main() {
        var gen = new Generator();
    
        Sys.println(gen.generate("src/gd_lisp/test/Test.gd"));
    }
}
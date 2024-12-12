package gd_lisp.lib;

import gd_lisp.lib.Generator;

class Main {
    static function main() {
        var gen = new Generator();
    
        var args = Sys.args();
    
        for(arg in args) {
            Sys.println([for (_ in 0...arg.length) '#'].join(''));
            Sys.println(arg);
            Sys.println([for (_ in 0...arg.length) '#'].join(''));
            Sys.println('');
            Sys.println(gen.generate(arg));
        }
    }
}
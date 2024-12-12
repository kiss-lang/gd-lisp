#! /bin/bash

if [ -z "$cases" ]; then
    for script in "src/gd_lisp/test/*.gd"; do
        haxe test.hxml --run gd_lisp.lib.Main $script
        Godot --headless --script $script
    done
else
    for case in "$cases"; do
        script=src/gd_lisp/test/${case}.gd
        haxe test.hxml --run gd_lisp.lib.Main $script 
        Godot --headless --script $script
    done
fi

#! /bin/bash

args="--headless --script"

app=$(which godot)
if [ -z "$app" ]; then
    app=$(which Godot)
fi

if [ -z "$cases" ]; then
    for script in "src/gd_lisp/test/*.gd"; do
        haxe test.hxml --run gd_lisp.lib.Main $script
        "$app" $args $script
    done
else
    for case in "$cases"; do
        script=src/gd_lisp/test/${case}.gd
        haxe test.hxml --run gd_lisp.lib.Main $script 
        "$app" $args $script
    done
fi

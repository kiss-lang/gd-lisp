- [x] Run test-cases from command line

- [x] allow multi-line blocks
- [x] `var`
- [x] gdscript lines at the end are getting clobbered somehow
- [x] fix + to capture args first
- [x] `set`

- [x] Redesign, implement, test, `begin` and `return` forms
- [x] Pass context into syntaxforms, so (return (if ...)) can return the result of both branches

- [x] fix `let` form
- [x] `func`

- [x] don't capture one-line args, save space
- [x] Operator =
- [x] Operators <, <=, >, >=
- [x] `and`
- [x] `or`
- [x] `not

- [x] `if`
- [x] `when`
- [x] `unless`
- [x] `cond`

- [x] array expressions

- [x] `nth`
- [x] += etc.
- [x] dict expressions
- [x] `for` -- also support dictionaries

- [x] `dictGet`
- [x] `dictSet`
- [x] `setNth`
- [x] arrow lambda

- [x] `while` will actually be tricky--if the args need expansion, the condition needs to be wrapped in a function so they expand every time!
- [ ] callField

- [ ] `ifLet`

- [ ] string multiplication
- [ ] $ reader macro
- [ ] breakpoint reader macro create `breakpoint` before expression

- [ ] Algebraic data types: data type that stores enum type and constructor as strings, arguments as array of variants
- [ ] `case`

- [ ] Add GENERATED, MODIFIED tags to blocks

- [ ] Document forms and check their arg number
- [ ] Proper error messages with line numbers

- [ ] Make prelude compiled in/relative
- [ ] Make gd-lisp run from command line as either compiled node or python
- [ ] Make gd-lisp run in Godot editor
- [ ] Make gd-lisp run in VSCode

- [ ] collapse the generated blocks in VScode
- [ ] collapse the generated blocks in Godot editor
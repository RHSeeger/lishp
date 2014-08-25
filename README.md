lishp
=====

A lisp interpreter written in shell script


Intersting things learned about bash

When using the 
    set -u
setting to throw an error on undefined variables, the following
    declare -a emptyArray=()
    ${emptyArray[@]}
winds up throwing an error. However, the following can be used to "work around" the issue
    ${emptyArray[@]:+${emptyArray[@]}}

Evaluator logic:

eval
    if Atom, return it (token to value)
    if Nil, return it (token to value)
    if List, eval first element, switch on result
        if Lambda, evaluate the rest of list and call lambda with args
        if Macro, call it with args (unevaluated)
        otherwise, error
    nothing else it can be

Random notes:
    The [RESULT="${RESULT}"], while effectively a noop, is used to signal to the
    code reader that we are returning a value, it's just the save value returned
    by the last thing we call.

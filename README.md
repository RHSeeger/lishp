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


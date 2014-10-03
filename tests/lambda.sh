#!/bin/bash

. ${BASH_SOURCE%/*}/test.sh

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
((lambda () 
         10)
  )
EOF
)
assert::equals "Integer :: 10" "${value}" "Basic lambda without parameters"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
((lambda (x y) 
         (+ x y))
  5 10)
EOF
)
assert::equals "Integer :: 15" "${value}" "Basic lambda with parameters"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(
  (
    (lambda (x) 
         (lambda (y) 
                 (+ x y))
    )
  2) 3)
EOF
)
assert::equals "Integer :: 5" "${value}" "Returning lambda with closure"




assert::report

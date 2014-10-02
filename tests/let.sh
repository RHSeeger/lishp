#!/bin/bash

. ${BASH_SOURCE%/*}/test.sh

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let ((x 2))
     x)
EOF
)
assert::equals "Integer :: 2" "${value}" "Basic let"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let ((x (+ 1 3)))
     x)
EOF
)
assert::equals "Integer :: 4" "${value}" "let with expression"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let ((x 2)
      (y x))
     y)
EOF
)
assert::equals "1" "$?" "let failing to read previous values"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let ((x 2))
     x
     (* 5 2))
EOF
)
assert::equals "Integer :: 10" "${value}" "let returning last value"

# ------------------------------------------------------------



assert::report

#!/bin/bash

. ${BASH_SOURCE%/*}/test.sh

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let* ((x 2))
      x)
EOF
)
assert::equals "Integer :: 2" "${value}" "Basic let*"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let* ((x 2)
       (y x))
      y)
EOF
)
assert::equals "Integer :: 2" "${value}" "let* reading previous values"

# ------------------------------------------------------------
value=$(../lishp.sh <<EOF
(let* ((x 2))
      x
      (* 5 x))
EOF
)
assert::equals "Integer :: 10" "${value}" "let returning last value"

# ------------------------------------------------------------


assert::report

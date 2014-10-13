<h1>lishp</h1>

A lisp interpreter written in shell script. It's incomplete... very much
so. There are very few commands defined. The key ones that are defined include:
* Various arithmetic functions (+, -, *, /)
* Various comparison operatores (<, >, <=, >=, =)
* let, let*
* lambda
* if

The next big things to add include define, some looping construct, cons, index,
etc. That being said, what's there now is enough to show the general idea of the
end goal. Simple programs can be written (as shown by the fibonacci example),
which is enough to see how things work. Time to work on the project is limited
and, combined with the extremely limited usefulness of the project, leads to the
fact that it may never get much further.

All that being said, its been a very fun learning project so far. Specifically,
it's taught me a lot about bash. I thought I was fairly proficient with it
before all this, but there's a lot of edge cases to be understood. Well worth
the time spent on it.


<h2>Intersting things learned about bash<h2>


When using the 
<pre>
    set -u
</pre>
setting to throw an error on undefined variables, the following
<pre>
    declare -a emptyArray=()
    ${emptyArray[@]}
</pre>
winds up throwing an error. However, the following can be used to "work around"
the issue
<pre>
    ${emptyArray[@]:+${emptyArray[@]}}
</pre>


<h2>Evaluator logic</h2>

eval
* if Atom, return it (token to value)
* if Nil, return it (token to value)
* if List, eval first element, switch on result
 * if Lambda, evaluate the rest of list and call lambda with args
 * if Macro, call it with args (unevaluated)
 * otherwise, error... nothing else it can be

<h2>Random notes</h2>
* The [RESULT="${RESULT}"], while effectively a noop, is used to signal to the code reader that we are returning a value, it's just the save value returned by the last thing we call.

* This is an implementation of a Lisp-1, meaning that functions and variables share the same namespace (like Scheme)


<h2>Examples</h2>


```
> ./lishp.sh examples/lambda.simple.lishp 
Sourced libraries!
Code read!
=================
((lambda (x y) 
         (+ x y))
  5 10)
=================
Parsed!
Environment setup!
Done!
=================
Integer :: 15
=================
```

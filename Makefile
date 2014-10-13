TESTABLES=\
	callable.lambda.sh \
	callable.sh \
	environment.sh \
	evaluator.functions.builtin.sh \
	evaluator.sh \
	parser.sh \
	specialforms.if.sh \
	specialforms.lambda.sh \
	specialforms.let.sh \
	specialforms.letstar.sh \
	specialforms.sh \
	variables.arraylist.sh \
	variables.atom.sh \
	variables.linkedlist.sh \
	variables.map.sh \
	variables.queue.sh \
	variables.sh \
	variables.stack.sh

test: $(TESTABLES:.sh=.test)
	@echo TESTS Completed

%.test : %.sh
	@echo == $< ==
	@./$<

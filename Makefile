TESTABLES=\
	variables.sh \
	variables.atom.sh \
	variables.arraylist.sh \
	variables.linkedlist.sh \
	variables.map.sh \
	variables.queue.sh \
	variables.stack.sh \
	environment.sh \
	evaluator.sh

test: $(TESTABLES:.sh=.test)

%.test : %.sh
	@echo == $< ==
	@./$<

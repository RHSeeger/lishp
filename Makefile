TESTABLES=environment.sh evaluator.sh variables.sh

test: environment.test evaluator.test variables.test

environment.test:
	-./environment.sh

evaluator.test:
	-./evaluator.sh

variables.test:
	-./variables.sh


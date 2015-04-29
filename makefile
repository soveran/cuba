.PHONY: test

default: test

test:
	cutest ./test/*.rb

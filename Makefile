.PHONY: fmt
fmt:
	@find . -path './.git' -prune \
			-o -path './test' -prune \
 			-o -name 'vendor' -prune \
 			-o -name '*.libsonnet' -print \
			-o -name '*.jsonnet' -print | \
		xargs -n 1 -- jsonnetfmt --no-use-implicit-plus -i

.PHONY: examples/parser.libsonnet.output.json
examples/parser.libsonnet.output.json:
	jrsonnet -J vendor examples/parser.libsonnet --max-stack 10000 --os-stack 50 > examples/parser.libsonnet.output.json

.PHONY: examples/eval.libsonnet.output.json
examples/eval.libsonnet.output.json:
	jrsonnet -J vendor examples/eval.libsonnet --max-stack 10000 --os-stack 50 > examples/eval.libsonnet.output.json

.PHONY: test
test: test_lexer test_parser

.PHONY: test_lexer
test_lexer:
	./go-jsonnet-test/test_lexer.sh

.PHONY: test_parser
test_parser:
	./go-jsonnet-test/test_parser.sh

.PHONY: test_eval
test_eval:
	./go-jsonnet-test/test_eval.sh

stdlib/generated.libsonnet:
	jrsonnet --max-stack 100000 -S -J vendor ./stdlib/main.libsonnet > ./stdlib/generated.libsonnet
	jsonnetfmt -i ./stdlib/generated.libsonnet

unicode/generated.libsonnet:
	jrsonnet ./unicode/main.libsonnet | sed 's;"\\\\u\(.*\)",\?;["\\\\u\1", "\\u\1"],;g' > unicode/generated.libsonnet
	jsonnetfmt -i ./unicode/generated.libsonnet

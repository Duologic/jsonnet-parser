.PHONY: fmt
fmt:
	@find . -path './.git' -prune \
			-o -path './test' -prune \
 			-o -name 'vendor' -prune \
 			-o -name '*.libsonnet' -print \
			-o -name '*.jsonnet' -print | \
		xargs -n 1 -- jsonnetfmt --no-use-implicit-plus -i

.PHONY: example.libsonnet.output.json
example.libsonnet.output.json:
	jrsonnet -J vendor example.libsonnet --max-stack=10000 --os-stack 500 > example.libsonnet.output.json

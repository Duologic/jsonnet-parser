.PHONY: fmt
fmt:
	@find . -path './.git' -prune -o -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- jsonnetfmt --no-use-implicit-plus -i

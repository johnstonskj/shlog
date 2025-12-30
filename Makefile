# -*- mode: makefile-gmake -*-

all: check test

SOURCES=shlog.bash shlog.plugin.zsh functions/shlog.zsh
TEST_SOURCES=spec/shlog_spec.sh spec/spec_helper.sh

check: $(SOURCES)
	shellcheck --check-sourced --color=auto --shell=bash $^

test: $(SOURCES) $(TEST_SOURCES)
	shellspec --shell /opt/homebrew/bin/bash --format documentation --output junit
	shellspec --shell /opt/homebrew/bin/zsh --format documentation --output junit
# -*- mode: makefile-gmake -*-

all: check test

SOURCES=shlog.bash shlog.plugin.zsh functions/*
TEST_SOURCES=spec/shlog_spec.sh spec/spec_helper.sh

check: check_sources check_test_sources

check_sources: $(SOURCES)
	shellcheck --check-sourced --color=auto --shell=bash $^

check_test_sources: $(TEST_SOURCES)
	shellspec --syntax-check

test: $(SOURCES) $(TEST_SOURCES)
	shellspec --shell /opt/homebrew/bin/zsh --format documentation --output junit
	shellspec --shell /opt/homebrew/bin/bash --format documentation --output junit

coverage: $(SOURCES) $(TEST_SOURCES)
	shellspec --kcov --kcov-options "--include-pattern=.sh,.bash,.zsh"

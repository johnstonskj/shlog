# -*- mode: makefile-gmake -*-

all: check test

check: shlog.bash shlog.plugin.zsh functions/shlog.zsh
	shellcheck --check-sourced --color=auto --shell=bash $^

test: spec/shlog_spec.sh spec/spec_helper.sh
	shellspec --shell /opt/homebrew/bin/bash
	shellspec --shell /opt/homebrew/bin/zsh
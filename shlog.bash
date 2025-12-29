# -*- mode: sh; eval: (sh-set-shell "bash") -*-

install_path() {
    local install_dir
    if [[ -n "${ZSH_VERSION}" ]]; then
        install_dir=${funcsourcetrace[1]}
    else
        install_dir=${BASH_SOURCE%/*}
    fi
    if [[ ${install_dir} == */* ]]; then
        install_dir=${install_dir%/*}
    else
        install_dir=.
    fi

    if [[ -n "${ZSH_VERSION}" ]]; then
        install_dir=${install_dir:A}
    else
        install_dir=$(realpath ${install_dir})
    fi
    echo -n ${install_dir}
}

source "$(install_path)/shlog.plugin.zsh"
shlog

source "$(install_path)/functions/shlog.zsh"

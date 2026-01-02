# -*- mode: sh; eval: (sh-set-shell "bash") -*-

emulate() {
    : # no-op
}

install_path() {
    local install_dir
    # shellcheck disable=SC2154
    if [[ -n "${ZSH_VERSION}" ]]; then
        install_dir="${funcsourcetrace[1]}"
    else
        install_dir="${BASH_SOURCE[1]}"
    fi
    if [[ "${install_dir}" == */* ]]; then
        install_dir="${install_dir%/*}"
    else
        install_dir='.'
    fi

    if [[ -n "${ZSH_VERSION}" ]]; then
        install_dir="${install_dir:A}"
    else
        install_dir=$(realpath "${install_dir}")
    fi
    echo -n "${install_dir}"
}

source "$(install_path)/shlog.plugin.zsh"

for file in $(install_path)/functions/*; do
    source "${file}"
done

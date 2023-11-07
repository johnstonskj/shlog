INSTALL=shlog.sh
INSTALLER=$(readlink -f $0)
INSTALL_FROM=$(dirname $INSTALLER)
INSTALL_TO=${XDG_DATA_HOME:-$HOME/.local/share/shlog}

if [[ "$1" == "remove" ]]; then
    rm ${INSTALL_TO}/${INSTALL}

    if [[ ! -d ${INSTALL_TO} ]]; then
        rmdir ${INSTALL_TO}
    fi
else
    if [[ ! -d ${INSTALL_TO} ]]; then
        mkdir -p ${INSTALL_TO}
    fi

    ln -s ${INSTALL_FROM}/${INSTALL} ${INSTALL_TO}/${INSTALL}
fi

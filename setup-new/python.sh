#!/usr/bin/env bash

# Python binaries (can also be mostly installed with a package manager but we
# do it with pipx to avoid dependency clash)
if ! type "pipx" > /dev/null 2>&1; then
    mkdir -p "$HOME"/.local/pipx/venvs
    curl https://raw.githubusercontent.com/cs01/pipx/master/get-pipx.py | python3
fi

pipx install --spec git+https://github.com/PyCQA/flake8 flake8 --verbose
pipx install beautysh --verbose
pipx install black --verbose
pipx install ipython --verbose
pipx install jupyter-core --verbose
pipx install mycli --verbose
pipx install pgcli --verbose
pipx install raiseorlaunch --verbose
pipx install vim-vint --verbose
pipx install yamllint --verbose
# TODO: Replace this once it's merged (and actually works)
# See: https://github.com/dbcli/mssql-cli/pull/228
# pipx install --spec git+https://github.com/cs01/mssql-cli@593d7f6516 mssql-cli --verbose


# Install some missing libraries in each venv
if type "pipx" > /dev/null 2>&1; then
    pipx_home="$HOME/.local/pipx/venvs"
    if [ -d "$pipx_home/jupyter-core" ]; then
        echo "Installing jupyter notebook..."
        "$pipx_home"/jupyter-core/bin/pip install jupyter
    fi
    if [ -d "$pipx_home/ipython" ]; then
        echo "Installing pandas for ipython..."
        "$pipx_home"/ipython/bin/pip install pandas
    fi
    if [ -d "$pipx_home/flake8" ]; then
        echo "Installing bugbear for flake8..."
        "$pipx_home"/flake8/bin/pip install flake8-bugbear
    fi
fi

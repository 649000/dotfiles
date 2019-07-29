#!/usr/bin/env bash
if type "pip3" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Installing Python3 modules...\\033[0m"
    pip_install_cmd='pip3 install --user '
    $pip_install_cmd cython
    $pip_install_cmd jedi
    $pip_install_cmd matplotlib
    $pip_install_cmd numpy
    $pip_install_cmd pandas
    $pip_install_cmd pdbpp
    $pip_install_cmd pipx
    if type "nvim" > /dev/null 2>&1; then
        $pip_install_cmd pynvim
    fi
    $pip_install_cmd pytest-cov
    $pip_install_cmd pytest
    $pip_install_cmd pytest-xdist
    $pip_install_cmd requests
    $pip_install_cmd Send2Trash
    $pip_install_cmd scikit-learn
    $pip_install_cmd scipy
    if [ "$OSTYPE" == 'linux-gnu' ]; then
        $pip_install_cmd Xlib
    fi
fi

# Python binaries (can also be mostly installed with a package manager but we
# do it with pipx to avoid dependency clash)
echo -e "\\033[1;34m--> Installing python binaries (with pipx)...\\033[0m"
pipx_install_cmd='pipx install --force --verbose'
pipx_inject_cmd='pipx inject --verbose'

$pipx_install_cmd flake8 --spec git+https://github.com/PyCQA/flake8
$pipx_inject_cmd flake8 flake8-bugbear flake8-docstrings
$pipx_install_cmd beautysh
$pipx_install_cmd black
$pipx_install_cmd httpie
$pipx_install_cmd ipython
$pipx_inject_cmd ipython numpy pandas matplotlib
# shellcheck disable=SC2102
$pipx_install_cmd isort[pyproject]
$pipx_install_cmd jupyter --include-deps
$pipx_install_cmd litecli
$pipx_install_cmd mssql-cli --spec git+https://github.com/dbcli/mssql-cli
$pipx_install_cmd mycli
$pipx_install_cmd mypy
if type "nvim" > /dev/null 2>&1; then
    $pipx_install_cmd neovim-remote
fi
$pipx_install_cmd pre-commit
$pipx_install_cmd pgcli --spec git+https://github.com/dbcli/pgcli
$pipx_install_cmd pipenv
$pipx_install_cmd pylint
if type "i3" > /dev/null 2>&1; then
    $pipx_install_cmd raiseorlaunch
fi
$pipx_install_cmd ranger-fm
$pipx_install_cmd sqlparse
$pipx_install_cmd trash-cli
$pipx_install_cmd unimatrix --spec git+https://github.com/will8211/unimatrix
$pipx_install_cmd vimiv --spec git+https://github.com/karlch/vimiv-qt
$pipx_inject_cmd vimiv pyqt5
$pipx_install_cmd vim-vint
$pipx_install_cmd yamllint

pipx_venvs="$PIPX_HOME/venvs"

# Set some mime defaults
if [ -d "$pipx_venvs/ranger-fm" ]; then
    echo "Adding desktop entry for ranger-fm..."
    xdg-desktop-menu install --novendor "$pipx_venvs/ranger-fm/share/applications/ranger.desktop"
    echo "xdg-mime query default inode/directory is: $(xdg-mime query default inode/directory)"
    echo "Adding man pages ranger-fm..."
    local_man_path="$HOME/.local/share/man/man1"
    mkdir -p "$local_man_path"
    cp -a "$pipx_venvs/ranger-fm/share/man/man1/." "$local_man_path"
    echo "Updating man's internal db..."
    sudo mandb
fi
if [ -d "$pipx_venvs/vimiv" ]; then
    echo "Adding desktop entry for vimiv..."
    mkdir -p "$pipx_venvs/vimiv/share"
    wget -P  "$pipx_venvs/vimiv/share" "https://raw.githubusercontent.com/karlch/vimiv-qt/master/misc/vimiv.desktop"
    xdg-desktop-menu install --novendor "$pipx_venvs/vimiv/share/vimiv.desktop"
    echo "xdg-mime query default image/png is: $(xdg-mime query default image/png)"
fi

# Copy pygment onedarkish style
echo -e "\\033[1;34m--> Installing onedarkish pygment style...\\033[0m"
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"
python_dir="$parent_dir/python"

ln_cmd='ln'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "gln" > /dev/null 2>&1; then
        ln_cmd='gln'
    else
        echo "Coreutils ln (gln) command not found!" 1>&2
        exit 1
    fi
fi

for dbcli in litecli mycli pgcli mssql-cli
do
    if [ -d "$pipx_venvs/$dbcli" ]; then
        styles_dir="$pipx_venvs/$dbcli/lib/python3.7/site-packages/pygments/styles"
        if [ -d "$styles_dir" ]; then
            $ln_cmd -fTs "$python_dir/onedarkish.py" "$styles_dir/onedarkish.py"
            echo Created symlink in "$styles_dir/onedarkish.py"
        fi
    fi

    # Workaround to fix mssql-cli
    if [[ "$dbcli" == 'mssql-cli' ]]; then
        package_dir="$pipx_venvs/$dbcli/lib/python3.7/site-packages/mssqlcli/mssqltoolsservice"
        wget https://github.com/dbcli/mssql-cli/raw/master/sqltoolsservice/manylinux1/Microsoft.SqlTools.ServiceLayer-linux-x64-netcoreapp2.1.tar.gz -P "$package_dir/bin"
        (
            cd "$package_dir/bin" || exit
            tar xf Microsoft.SqlTools.ServiceLayer-linux-x64-netcoreapp2.1.tar.gz
            rm -rf Microsoft.SqlTools.ServiceLayer-linux-x64-netcoreapp2.1.tar.gz
        )
    fi
done

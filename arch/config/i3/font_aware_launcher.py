#!/usr/bin/env python3
"""Launch programs adjusting fonts if necessary."""

import os
import subprocess
import sys

import i3ipc


def _sh_no_block(cmd, *args, **kwargs):
    if isinstance(cmd, str):
        cmd = cmd.split()
    return subprocess.Popen(cmd, *args, **kwargs)


def _sh(cmd, *args, **kwargs):
    res, _ = _sh_no_block(cmd, *args, stdout=subprocess.PIPE, **kwargs).communicate()
    return res


def run_app(app, subcmd):
    """Run gdk app adjusting font size if necessary."""
    i3 = i3ipc.Connection()
    ws = i3.get_tree().find_focused().workspace()
    is_hidpi = ws.ipc_data['output'] == 'eDP1'
    nr_monitors = int(
        [
            line.decode('ascii').split()
            for line in _sh('xrandr --listactivemonitors').splitlines()
        ][0][-1]
    )

    gdk = ''
    qt = ''
    if is_hidpi:
        gdk += 'GDK_SCALE=2 '
        if nr_monitors == 1:
            gdk += 'GDK_DPI_SCALE=0.5 '
        if nr_monitors > 1:
            qt += 'QT_SCALE_FACTOR=2 '

    if app == 'connman':
        # It might open in a hidpi screen or not
        _sh_no_block(
            ['raiseorlaunch', '-c', 'Connman-gtk', '-f', '-e', f'"{gdk}connman-gtk"']
        )
    elif app == 'zathura':
        # It might open in a hidpi screen or not
        _sh_no_block(
            ['raiseorlaunch', '-c', 'Zathura', '-C', '-f', '-e', f'"{gdk}zathura"']
        )
    elif app == 'pavucontrol':
        # It might open in a hidpi screen or not
        _sh_no_block(
            ['raiseorlaunch', '-c', 'pavucontrol', '-f', '-e', f'"{gdk}pavucontrol"']
        )
    elif app == 'transmission':
        # It always opens in hidpi screen
        gdk += 'GDK_SCALE=2 '
        _sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'Transmission-gtk',
                '-W',
                '3',
                '-f',
                '-e',
                f'"{gdk}transmission-gtk"',
            ]
        )
    elif app == 'peek':
        # It might open in a hidpi screen or not
        _sh_no_block(['raiseorlaunch', '-c', 'Peek', '-f', '-e', f'"{gdk}peek"'])
    elif app == 'thunderbird':
        # It always opens in hidpi screen
        gdk += 'GDK_SCALE=2 '
        _sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'Thunderbird',
                '-W',
                '2',
                '-f',
                '-e',
                f'"{gdk}thunderbird"',
            ]
        )
    elif app == 'gtk_dialog':
        if subcmd is None:
            raise ValueError('Missing type of dialog!')
        gtk_dialog = ['gtk_dialog', '-t']
        if subcmd == 'poweroff':
            gtk_dialog += [
                "Power Management",
                '-m',
                "Do you want to poweroff?",
                '-a',
                'systemctl poweroff',
            ]
        elif subcmd == 'reboot':
            gtk_dialog += [
                "Power Management",
                '-m',
                "Do you want to reboot?",
                '-a',
                'systemctl reboot',
            ]
        elif subcmd == 'quit':
            gtk_dialog += [
                "App Management",
                '-m',
                "Do you want to quit all apps?",
                '--shell',
                '-a',
                '$HOME/.config/i3/custom_kill.py -w all',
            ]
        elif subcmd == 'usb':
            gtk_dialog += [
                "Media Management",
                '-m',
                "Do you want to eject media drive?",
                '-a',
                'udiskie-umount -a',
            ]
        elif subcmd == 'trash':
            gtk_dialog += [
                "Trash Management",
                '-m',
                "Do you want to empty the trash?",
                '--shell',
                '-a',
                "trash-empty && pkill -INT -f trash-list && "
                "xdotool key Super_L+Control+b && "
                "dunstify -t 2500 -i trashindicator 'Trash Can emptied!'",
            ]
        gtk_env = dict([i.split('=') for i in gdk.split()])  # type: ignore
        _sh_no_block(
            gtk_dialog, env={**os.environ, **gtk_env},
        )
    elif app == 'vimiv':
        # It might open in a hidpi screen or not
        _sh_no_block(
            ['raiseorlaunch', '-c', 'vimiv', '-C', '-f', '-e', f'"{qt}vimiv"'],
        )
    elif app == 'rofi':
        if subcmd is None:
            raise ValueError('Missing rofi subcommand!')
        rofi_fsize = 11
        rofi_yoffset = -50
        if is_hidpi & (nr_monitors > 1):
            rofi_fsize *= 2
            rofi_yoffset *= 2
        rofi_base = f'rofi -font "Noto Sans Mono {rofi_fsize}" -yoffset {rofi_yoffset}'
        if subcmd == 'apps':
            rofi_cmd = [f'{rofi_base} -combi-modi drun,run -show combi']
        elif subcmd == 'pass':
            rofi_cmd = [
                f"gopass ls --flat | {rofi_base} -dmenu -p gopass | "
                "xargs --no-run-if-empty gopass show -c"
            ]
        _sh_no_block(rofi_cmd, shell=True)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('application')
    parser.add_argument('subcommand', nargs='?', default=None)
    parse_args = parser.parse_args()

    run_app(parse_args.application, parse_args.subcommand)
    sys.exit(0)

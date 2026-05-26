# Moonfly colorscheme for ranger
# Based on the Dracula ranger theme included in this repo.
# Relies on the terminal defining colors 0-15 as the moonfly palette:
#
#  0  #323437  black       8   #949494  br_black (muted)
#  1  #ff5454  red         9   #ff5189  br_red
#  2  #8cc85f  green      10   #36c692  br_green
#  3  #e3c78a  yellow     11   #c6c684  br_yellow
#  4  #80a0ff  blue       12   #74b2ff  br_blue
#  5  #cf87e8  magenta    13   #ae81ff  br_magenta
#  6  #79dac8  cyan       14   #85dc85  br_cyan
#  7  #c6c6c6  white      15   #e4e4e4  br_white

from __future__ import absolute_import, division, print_function

from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import (
    black,
    blue,
    cyan,
    green,
    magenta,
    red,
    white,
    yellow,
    default,
    normal,
    bold,
    reverse,
    default_colors,
)


class Moonfly(ColorScheme):
    progress_bar_color = 12  # br_blue (#74b2ff) — moonfly accent

    def verify_browser(self, context, fg, bg, attr):
        if context.selected:
            attr = reverse
        else:
            attr = normal
        if context.empty or context.error:
            bg = 1   # red background on error
            fg = 0   # black text on error
        if context.border:
            fg = default
        if context.document:
            attr |= normal
            fg = 7   # white — plain documents
        if context.media:
            if context.image:
                attr |= normal
                fg = 3   # yellow — images
            elif context.video:
                fg = 1   # red — video
            elif context.audio:
                fg = 6   # cyan — audio
            else:
                fg = 10  # br_green — other media
        if context.container:
            attr |= bold
            fg = 9   # br_red — archives/containers
        if context.directory:
            attr |= bold
            fg = 4   # blue (#80a0ff) — moonfly primary accent for dirs
        elif context.executable and not any(
            (context.media, context.container, context.fifo, context.socket)
        ):
            attr |= bold
            fg = 2   # green — executables
        if context.socket:
            fg = 5   # magenta — sockets
            attr |= bold
        if context.fifo or context.device:
            fg = 3   # yellow — special files
            if context.device:
                attr |= bold
        if context.link:
            fg = 6 if context.good else 9   # cyan (good) / br_red (broken)
        if context.tag_marker and not context.selected:
            attr |= bold
            if fg in (red, magenta):
                fg = 1
            else:
                fg = 15  # br_white — tag markers
        if not context.selected and (context.cut or context.copied):
            fg = 8   # muted (#949494) — cut/copied items
            attr |= bold
        if context.main_column:
            if context.selected:
                attr |= bold
            if context.marked:
                attr |= bold
                fg = 11  # br_yellow — marked items
        if context.badinfo:
            if attr & reverse:
                bg = 5
            else:
                fg = 5   # magenta — bad info

        if context.inactive_pane:
            fg = 8   # muted — inactive panes

        return fg, bg, attr

    def verify_titlebar(self, context, fg, bg, attr):
        attr |= bold
        if context.hostname:
            fg = 1 if context.bad else 2   # red (bad) / green (ok)
        elif context.directory:
            fg = 4   # blue — path in titlebar
        elif context.tab:
            if context.good:
                bg = 2   # green tab background when good
        elif context.link:
            fg = 6   # cyan — links in titlebar

        return fg, bg, attr

    def verify_statusbar(self, context, fg, bg, attr):
        if context.permissions:
            if context.good:
                fg = 2   # green — good permissions
            elif context.bad:
                bg = 5   # magenta bg — bad permissions
                fg = 8
        if context.marked:
            attr |= bold | reverse
            fg = 3   # yellow — marked state
        if context.frozen:
            attr |= bold | reverse
            fg = 6   # cyan — frozen
        if context.message:
            if context.bad:
                attr |= bold
                fg = 1   # red — error messages
        if context.loaded:
            bg = self.progress_bar_color   # br_blue progress bar
        if context.vcsinfo:
            fg = 4   # blue — branch info
            attr &= ~bold
        if context.vcscommit:
            fg = 3   # yellow — commit hash
            attr &= ~bold
        if context.vcsdate:
            fg = 6   # cyan — commit date
            attr &= ~bold

        return fg, bg, attr

    def verify_taskview(self, context, fg, bg, attr):
        if context.title:
            fg = 4   # blue — task titles

        if context.selected:
            attr |= reverse

        if context.loaded:
            if context.selected:
                fg = self.progress_bar_color
            else:
                bg = self.progress_bar_color

        return fg, bg, attr

    def verify_vcsfile(self, context, fg, bg, attr):
        attr &= ~bold
        if context.vcsconflict:
            fg = 5   # magenta — conflicts
        elif context.vcschanged:
            fg = 1   # red — changed
        elif context.vcsunknown:
            fg = 1   # red — unknown
        elif context.vcsstaged:
            fg = 2   # green — staged
        elif context.vcssync:
            fg = 2   # green — in sync
        elif context.vcsignored:
            fg = default

        return fg, bg, attr

    def verify_vcsremote(self, context, fg, bg, attr):
        attr &= ~bold
        if context.vcssync or context.vcsnone:
            fg = 2   # green — synced
        elif context.vcsbehind:
            fg = 1   # red — behind
        elif context.vcsahead:
            fg = 6   # cyan — ahead
        elif context.vcsdiverged:
            fg = 5   # magenta — diverged
        elif context.vcsunknown:
            fg = 1   # red — unknown

        return fg, bg, attr

    def use(self, context):
        fg, bg, attr = default_colors

        if context.reset:
            return default_colors

        elif context.in_browser:
            fg, bg, attr = self.verify_browser(context, fg, bg, attr)

        elif context.in_titlebar:
            fg, bg, attr = self.verify_titlebar(context, fg, bg, attr)

        elif context.in_statusbar:
            fg, bg, attr = self.verify_statusbar(context, fg, bg, attr)

        if context.text:
            if context.highlight:
                attr |= reverse

        if context.in_taskview:
            fg, bg, attr = self.verify_taskview(context, fg, bg, attr)

        if context.vcsfile and not context.selected:
            fg, bg, attr = self.verify_vcsfile(context, fg, bg, attr)

        elif context.vcsremote and not context.selected:
            fg, bg, attr = self.verify_vcsremote(context, fg, bg, attr)

        return fg, bg, attr

package oak_tui

// https://github.com/dankamongmen/notcurses/blob/93a4890f4c2b491cda62fea5110995c6a25691e2/src/lib/termdesc.h
// https://github.com/dankamongmen/notcurses/blob/93a4890f4c2b491cda62fea5110995c6a25691e2/src/lib/windows.c

// https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences

// TODO
Escape_Code :: enum u16 {
    MoveCursor, // "cup" move cursor to absolute x, y position
    MoveCursorH, // "hpa" move cursor to absolute horizontal position
    MoveCursorV, // "vpa" move cursor to absolute vertical position
    MoveCursorUp, // "cuu" move n cells up
    MoveCursorDown, // "cud" move n cells down
    MoveCursorBack, // "cub" move n cells back (left)
    MoveCursorForward, // "cuf" move n cells forward (right)
    ScrollBy, // "indn" scroll n lines up
    EraseScreen, // "clear" clear screen and home cursor
    EraseLine, // "el" clear to end of line, inclusive
    EraseRectangle, // DECERA, VT400, rectangular erase (CSI Pt; Pl; Pb; Pr$ z)
    SetBackgroundStyle, // 40-37 (8), 48 (256, or rgb), 49 default
    SetForgroundStyle, // 30-37 (8), 38 (256, or rgb), 39 default
    ResetStyle, // "sgr0" turn off all styles
    HideCursor, // "civis" make the cursor invisiable
    ShowCursor, // "cnorm" restore the cursor to normal
    EnterAltScreen, // "smcup" enter alternate screen
    ExitAltScreen, // "rmcup" leave alternate screen
    PushCursorStack, // ?? "sc" push the cursor onto the stack
    PopCursorStack, // ?? "rc" pop the cursor off the stack
    // Application synchronized updates, not present in terminfo
    // (https://gitlab.com/gnachman/iterm2/-/wikis/synchronized-updates-spec)
    BSUM, // Begin Synchronized Update Mode
    ESUM, // End Synchronized Update Mode 
}

get_escape :: proc(code: Escape_Code) -> (escape: string, is_formatted: bool) {
    return expand_values(_escape_table[code])
}

@(private)
_escape_table: [Escape_Code]struct {
    escape:       string,
    is_formatted: bool,
}

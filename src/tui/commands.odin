package oak_tui

DEV_BUILD :: #config(DEV_BUILD, ODIN_DEBUG)

@(require) import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

@(private)
_buffer: [8192]byte

// Convenience function that sets alt buffer, title, and then disables it all at scope exit.
@(deferred_none = scoped_tui_application_end)
scoped_tui_application :: proc(title: string) {
    enable_alt_buffer(true)
    set_title(title)
    cursor_move(0, 0)
}

@(private)
scoped_tui_application_end :: proc() {
    enable_alt_buffer(false)
    enable_mouse_input(false)
    show_cursor(true)
    reset()
}

write :: proc(values: ..any) {
    fmt.print(..values)
}

writef :: proc(format: string, values: ..any) {
    fmt.printf(format, ..values)
}

// Reads input from stdin. 
@(require_results)
read :: proc() -> (string, bool) #optional_ok {
    slice.zero(_buffer[:])
    n, ok := _read()
    if ok do return string(_buffer[:n]), true
    else do return {}, false
}

// Reads input from stdin but trims line break characters (\r\n).
@(require_results)
read_input :: proc() -> (string, bool) #optional_ok {
    str, ok := read()
    return ok ? strings.trim_right(str, "\r\n") : str, ok
}

// Get the size of the window.
window_size :: proc() -> [2]int {
    return _window_size()
}

// Enable use of the alt buffer.
enable_alt_buffer :: proc(enable: bool) {
    writef("\e[?1049{}", enable ? "h" : "l")
}

// Enables or disables mouse input.
enable_mouse_input :: proc(enable: bool) {
    MOUSE_CAPTURE :: "\e[?1003{}"
    SGR_MOUSE :: "\e[?1006{}"
    writef(MOUSE_CAPTURE, enable ? "h" : "l")
    writef(SGR_MOUSE, enable ? "h" : "l")
}

// Sets the terminal title.
set_title :: proc(title: string) {
    writef("\e]0;{}\a", title)
}

// Move the cursor to (x, y)
cursor_move :: proc(x, y: int) {
    CURSOR_MOVE_HOME :: "\e[{};{}H"
    fmt.printf(CURSOR_MOVE_HOME, 1 + y, 1 + x)
}

cursor_move_up :: proc(n := 1) {
    write("\e[{}A", n)
}

cursor_move_down :: proc(n := 1) {
    write("\e[{}B", n)
}

cursor_move_right :: proc(n := 1) {
    write("\e[{}C", n)
}

cursor_move_left :: proc(n := 1) {
    write("\e[{}D", n)
}

cursor_move_down_lines :: proc(n := 1) {
    write("\e[{}E", n)
}

cursor_move_up_lines :: proc(n := 1) {
    write("\e[{}F", n)
}

cursor_set_x :: proc(x: int) {
    write("\e[{}G", x)
}

show_cursor :: proc(show: bool) {
    CURSOR_SHOW :: "\e[?25h"
    CURSOR_HIDE :: "\e[?25l"
    write(show ? CURSOR_SHOW : CURSOR_HIDE)
}

// Save the cursor state.
cursor_save :: proc() {
    unimplemented()
}

// Restore the cursor state.
cursor_restore :: proc() {
    unimplemented()
}

@(require_results)
get_cursor_position :: proc() -> [2]int {

    RESPONSE_CURSOR_POSITION :: "\e[{ROW};{COL}R"
    QUERY_CURSOR_POSITION :: "\e[6n"

    write(QUERY_CURSOR_POSITION)

    if response, ok := read(); ok {
        fmt.printf("cursor response 1: {}", response)
    }

    if response, ok := read(); ok {
        fmt.printf("cursor response 2: {}", response)
    }

    //     split := strings.index_rune(response[2:], ';')

    //     row_str := response[2:split]
    //     col_str := response[split + 1:len(response) - 1]

    //     fmt.printf("cursor is at: {}, {}", col_str, row_str)

    return {}
}

Color8 :: enum {
    Black  = 0,
    Red    = 1,
    Green  = 2,
    Yellow = 3,
    Blue   = 4,
    Purple = 5,
    Cyan   = 6,
    White  = 7,
}

// Update the foreground color.
forground :: proc(color: Color8) {

    writef("\e[{}m", get(color))

    get :: proc(color: Color8) -> string {
        switch color {
        case .Black:
            return "30"
        case .Red:
            return "31"
        case .Green:
            return "32"
        case .Yellow:
            return "33"
        case .Blue:
            return "34"
        case .Purple:
            return "35"
        case .Cyan:
            return "36"
        case .White:
            return "37"
        case:
            unreachable()
        }
    }
}

// Update the background color.
background :: proc(color: Color8) {

    writef("\e[{}m", get(color))

    get :: proc(color: Color8) -> string {
        switch color {
        case .Black:
            return "40"
        case .Red:
            return "41"
        case .Green:
            return "42"
        case .Yellow:
            return "43"
        case .Blue:
            return "44"
        case .Purple:
            return "45"
        case .Cyan:
            return "46"
        case .White:
            return "47"
        case:
            unreachable()
        }
    }
}

// Reset all graphic settings (ie. default colors)
reset :: proc() {
    SGR_RESET :: "\e[m"
    write(SGR_RESET)
}

// Erse the entire screen.
erase_screen :: proc() {
    ERASE_SCREEN :: "\e[2J"
    write(ERASE_SCREEN)
}

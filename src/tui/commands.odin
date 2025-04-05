package oak_tui

DEV_BUILD :: #config(DEV_BUILD, ODIN_DEBUG)

@(require) import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

@(private)
_buffer: [8192]byte

// Write a string to stdout.
write :: proc(text: string) {
    os.write(os.stdout, transmute([]byte)text)
}

// Reads input from stdin but trims line break characters (\r\n).
@(require_results)
read_input :: proc() -> string {
    return strings.trim_right(read(), "\r\n")
}

// Reads input from stdin. 
@(require_results)
read :: proc() -> string {
    slice.zero(_buffer[:])
    n, err := os.read(os.stdin, _buffer[:])
    if err == nil do return string(_buffer[:n])
    else do return {}
}

// Helper utility that enables the alt buffer, sets the title, and disables the alt buffer at scope exit.
@(deferred_none = scoped_tui_application_end)
scoped_tui_application :: proc(title: string) {
    enable_alt_buffer(true)
    cursor_move_home()
    set_title(title)
}

@(private)
scoped_tui_application_end :: proc() {
    enable_alt_buffer(false)
    show_cursor(true)
}

// Get the size of the window.
window_size :: proc() -> [2]int {
    return _window_size()
}

// set_input_mode(.LineInput) // one line at a time (typical terminal)
// set_input_mode(.CharInput) // one char at a time (tui apps)

// Enable use of the alt buffer.
enable_alt_buffer :: proc(enable: bool) {
    ENABLE_ALT_BUFFER :: "\e[?1049h"
    DISABLE_ALT_BUFFER :: "\e[?1049l"
    write(enable ? ENABLE_ALT_BUFFER : DISABLE_ALT_BUFFER)
}

// Sets the terminal title.
set_title :: proc(title: string) {
    write("\e]0;")
    write(title)
    write("\a")
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

// Move the cursor home (0, 0)
cursor_move_home :: proc() {
    CURSOR_MOVE_HOME :: "\e[H"
    write(CURSOR_MOVE_HOME)
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

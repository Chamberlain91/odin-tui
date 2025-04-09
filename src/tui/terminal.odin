package oak_tui

DEV_BUILD :: #config(DEV_BUILD, ODIN_DEBUG)

import "core:container/queue"
@(require) import "core:fmt"
import "core:strconv"
import "core:strings"

@(private)
_input: queue.Queue(byte)

@(private)
// TODO: perhaps a terminal state object
Terminal :: struct {
    name:    string,
    stdout:  uint,
    stdin:   uint,
    using _: Terminal_Capabilities,
    using _: Terminal_State,
}

@(private)
Terminal_Capabilities :: struct {
    // TODO: color8
    // TODO: color256
    // TODO: 
}

@(private)
Terminal_State :: struct {
    is_alt_screen: bool,
    title:         string,
    cursor:        [2]int,
    size:          [2]int,
}

@(private)
// TODO
Input :: struct {
    event_id: int, // ???
    x, y:     int, // -1 for undefined
    is_alt:   bool,
    is_shift: bool,
    is_ctrl:  bool,
}

// Initialize the terminal session. 
init_terminal :: proc(title: string) {

    // Allocate input queue
    queue.init(&_input)

    // Initialize platform specific
    _init_terminal()

    // Initialize escape table.
    _init_escape_table()

    // ?? Set the terminal title
    set_title(title)
}

// Shutdown the terminal session.
shutdown_terminal :: proc() {

    queue.destroy(&_input)

    enable_mouse_input(false)
    enable_alt_buffer(false)
    show_cursor(true)

    reset()
}

// Determines if the terminal is considered interactive.
is_interactive :: #force_inline proc() -> bool {
    return is_terminal_input() && is_terminal_output()
}

// Determines if the input is from a terminal (as opposed to read from a file or pipe).
is_terminal_input :: #force_inline proc() -> bool {
    return _is_tty_in()
}

// Determines if the output is to a terminal (as opposed to writing to a file or pipe).
is_terminal_output :: #force_inline proc() -> bool {
    return _is_tty_out()
}

process_input :: proc() {

    buf: [1024]byte
    ok: bool
    n: int

    for true {
        if n, ok = _read(buf[:]); ok && n > 0 {
            queue.append(&_input, ..buf[:n])
        } else do break
    }
}

/// Returns the number of bytes available in the input queue.
input_available :: proc() -> int {
    return queue.len(_input)
}

/// Looks `i` bytes ahead in the input queue.
input_peek :: proc(i := 0, loc := #caller_location) -> byte {
    return queue.get(&_input, i, loc = loc)
}

/// Consumes `n` bytes from the input queue.
input_read :: proc(n: int = -1, allocator := context.temp_allocator, loc := #caller_location) -> string {

    process_input()

    n := n
    if n < 0 {
        n = input_available()
    }

    sb: strings.Builder
    strings.builder_init(&sb, n, allocator, loc)
    for i := 0; i < n; i += 1 {
        strings.write_byte(&sb, queue.get(&_input, i, loc))
    }
    queue.consume_front(&_input, n, loc)

    return strings.to_string(sb)
}

// Get the size of the window.
window_size :: proc() -> [2]int {
    return _window_size()
}

// Enable use of the alt buffer.
enable_alt_buffer :: proc(enable: bool) {
    fmt.print(get_escape(enable ? .EnterAltScreen : .ExitAltScreen))
}

// Enables or disables mouse input.
enable_mouse_input :: proc(enable: bool) {

    // \e[?1049h
    // \e[0m
    // \e[2J
    // \e[?1003h
    // \e[?1015h
    // \e[?1006h
    // show_cursor(false)

    MOUSE_CAPTURE :: "\e[?1003{}"
    fmt.printf(MOUSE_CAPTURE, enable ? "h" : "l")
}

// Sets the terminal title.
set_title :: proc(title: string) {
    // writef("\e]0;{}\a", title)
    fmt.printf("\e]2;{}\e\\", title)
}

// Move the cursor to (x, y)
cursor_move :: proc(x, y: int) {
    CURSOR_MOVE_HOME :: "\e[{};{}H"
    fmt.printf(CURSOR_MOVE_HOME, 1 + y, 1 + x)
}

cursor_move_up :: proc(n := 1) {
    fmt.print("\e[{}A", n)
}

cursor_move_down :: proc(n := 1) {
    fmt.print("\e[{}B", n)
}

cursor_move_right :: proc(n := 1) {
    fmt.print("\e[{}C", n)
}

cursor_move_left :: proc(n := 1) {
    fmt.print("\e[{}D", n)
}

cursor_move_down_lines :: proc(n := 1) {
    fmt.print("\e[{}E", n)
}

cursor_move_up_lines :: proc(n := 1) {
    fmt.print("\e[{}F", n)
}

cursor_set_x :: proc(x: int) {
    fmt.print("\e[{}G", x)
}

show_cursor :: proc(show: bool) {
    CURSOR_SHOW :: "\e[?25h"
    CURSOR_HIDE :: "\e[?25l"
    fmt.print(show ? CURSOR_SHOW : CURSOR_HIDE)
}

// Save the cursor state.
cursor_save :: proc() {
    unimplemented()
}

// Restore the cursor state.
cursor_restore :: proc() {
    unimplemented()
}

// @(require_results)
// get_cursor_position :: proc() -> [2]int {

//     RESPONSE_CURSOR_POSITION :: "\e[{ROW};{COL}R"
//     QUERY_CURSOR_POSITION :: "\e[6n"
//     BAD_VALUE :: [2]int{-1, -1}

//     write(QUERY_CURSOR_POSITION)

//     buffer: [64]byte
//     split: int
//     n: int

//     // Do we have enough conte
//     if input_peek(0) != '\e' && input_peek(1) != '[' {
//         return BAD_VALUE
//     }

//     for n < len(buffer) {
//         if ch, ok := read_byte(); ok {
//             if ch == ';' do split = n
//             if ch == 'R' do break
//             buffer[n] = ch
//             n += 1
//         }
//     }

//     // ...
//     response := string(buffer[:n])

//     // Must be at least 6 bytes.
//     if n < 6 {
//         fmt.panicf("Response was {} but needs to be at least 6.", n)
//     }

//     // Must start with '\e['
//     if !strings.starts_with(response, "\e[") {
//         panic("Query position response was malformed.")
//     }

//     // Parse reply
//     row, _ := strconv.parse_int(response[2:split])
//     col, _ := strconv.parse_int(response[split + 1:])

//     return {col - 1, row - 1}
// }

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

    fmt.printf("\e[{}m", get(color))

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

    fmt.printf("\e[{}m", get(color))

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
    fmt.print(SGR_RESET)
}

// Erse the entire screen.
erase_screen :: proc() {
    ERASE_SCREEN :: "\e[2J"
    fmt.print(ERASE_SCREEN)
}

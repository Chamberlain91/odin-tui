package term

import "core:container/queue"
import "core:fmt"
import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"

DEV_BUILD :: #config(DEV_BUILD, ODIN_DEBUG)

// Reference:
// https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Any-event-tracking

@(private)
_events: queue.Queue(Event)

initialize :: proc() {
    _initialize()
}

shutdown :: proc() {
    queue.destroy(&_events)
    _shutdown()
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

enable_alternate_screen :: proc(enable := true) {
    fmt.print(enable ? "\e[?1049h" : "\e[?1049l")
}

enable_mouse :: proc(enable := true) {
    fmt.print(enable ? "\e[?1003h" : "\e[?1003l") // ANY EVENT TRACKING
    fmt.print(enable ? "\e[?1006h" : "\e[?1006l") // SGR EXTENSION
}

show_cursor :: proc(visible := true) {
    fmt.print(visible ? "\e[?25h" : "\e[?25l")
}

process_input :: proc() {

    for _has_stdin_input() {
        _read_stdin()
    }

    for input_available() > 0 {

        // Attempt to read various escape sequences.
        if _process_mouse_input() do continue

        // Nothing more to do if we have consumed everything.
        if input_available() == 0 do break

        // TODO: How do we detect just pressing escape?
        // - Read somewhere they use a timer.

        // Append key event to queue.
        ev := Key_Event {
            ch  = rune(input_get(0)),
            key = .Other,
        }
        queue.append(&_events, ev)

        os.write_byte(os.stdout, input_get(0))
        input_consume(1)
    }
}

size :: proc() -> [2]int {
    return _terminal_size()
}

// Determines if any events have been placed in the queue.
has_event :: proc() -> bool {
    return queue.len(_events) > 0
}

// Gets the next event to process.
get_event :: proc(loc := #caller_location) -> (Event, bool) {
    if has_event() {
        return queue.pop_back(&_events, loc), true
    }
    return {}, false
}

cursor_position :: proc() -> [2]int {
    // TODO
    return INVALID_CURSOR_POSITION
}

set_cursor_position :: proc(pos: [2]int) {
    fmt.printf("\e[%d;%dH", pos.y, pos.x)
}

move_cursor_up :: proc() {
    // TODO
}

move_cursor_down :: proc() {
    // TODO
}

move_cursor_forward :: proc() {
    // TODO
}

move_cursor_back :: proc() {
    // TODO
}

save_cursor :: proc() {
    // TODO
}

restore_cursor :: proc() {
    // TODO
}

erase_screen :: proc(mode := Erase_Mode.Whole) {
    switch mode {
    case .Whole:
        fmt.print("\e[2J")
    case .Before:
    // TODO above cursor
    case .After:
    // TODO below cursor
    }
}

erase_line :: proc(mode := Erase_Mode.Whole) {
    switch mode {
    case .Whole:
    // TODO whole line
    case .Before:
    // TODO line before cursor
    case .After:
    // TODO line after cursor
    }
}

Erase_Mode :: enum {
    Whole,
    Before,
    After,
}

foreground_color :: proc() -> Color {
    // TODO
    return .Default
}

background_color :: proc() -> Color {
    // TODO
    return .Default
}

set_foreground_color :: proc(color: Color) {
    fmt.printf("\e[%vm", 30 + int(color))
}

set_background_color :: proc(color: Color) {
    fmt.printf("\e[%vm", 40 + int(color))
}

// TODO: Text attributes?

reset_color :: proc() {
    fmt.print("\e[0m")
}

@(private)
_interpolate :: proc(str: string, args: ..any) -> string {
    @(static) temp: [32]byte
    return fmt.bprintf(temp[:], str, ..args)
}

INVALID_CURSOR_POSITION :: [2]int{-1, -1}

Color :: enum {
    Black   = 0,
    Red     = 1,
    Green   = 2,
    Yellow  = 3,
    Blue    = 4,
    Magenta = 5,
    Cyan    = 6,
    White   = 7,
    Default = 9,
}

Event :: union {
    Mouse_Event,
    Size_Event,
    Key_Event,
}

Mouse_Event :: struct {
    button:    Mouse_Button,
    modifiers: Modifiers,
    pressed:   bool,
    position:  [2]int,
}

Mouse_Button :: enum {
    Left        = 0,
    Middle      = 1,
    Right       = 2,
    None        = 3,
    Scroll_Up   = 4,
    Scroll_Down = 5,
}

Key_Event :: struct {
    key: Key,
    ch:  rune,
}

Size_Event :: struct {
    size: [2]int,
}

Key :: enum {
    Escape,
    Ctrl,
    Alt,
    Shift,
    Backspace,
    Return,
    Tab,
    Insert,
    Delete,
    Home,
    End,
    PageUp,
    PageDown,
    // A-Z
    // 0-9
    // !@#$%^&*()-_=+,<.>/?;:'"[{]}\|`~
    Other,
}

Modifier :: enum u8 {
    Shift,
    Alt,
    Ctrl,
}

Modifiers :: bit_set[Modifier;u8]

// -----------------------------------------------------------------------------

@(private)
_input: queue.Queue(byte)

@(private)
input_available :: proc() -> int {
    return queue.len(_input)
}

@(private)
input_get :: proc(i: int, loc := #caller_location) -> byte {

    for i >= input_available() {
        log.warnf("Reading std because queue was too shallow ({}/{})", i, input_available())
        _read_stdin()
    }

    return queue.get(&_input, i, loc)
}

@(private)
input_consume :: proc(n: int, loc := #caller_location) {
    queue.consume_front(&_input, n, loc)
}

@(private)
input_starts_with :: proc(pattern: string) -> bool {

    @(static) buffer: [64]byte
    for i in 0 ..< len(pattern) {
        buffer[i] = input_get(i)
    }

    return strings.starts_with(string(buffer[:len(pattern)]), pattern)
}

@(private)
input_index :: proc(offset: int, values: ..byte, look_ahead := 8, loc := #caller_location) -> int {

    for i in 0 ..< look_ahead {
        x := input_get(offset + i, loc)
        for v in values {
            if x == v do return offset + i
        }
    }

    return -1
}

@(private)
input_copy :: proc(buffer: []byte, offset: int, count: int, loc := #caller_location) -> []byte {
    for i in 0 ..< count {
        buffer[i] = input_get(offset + i, loc)
    }
    return buffer[:count]
}

// -----------------------------------------------------------------------------

@(private)
_process_mouse_input :: proc() -> bool {

    state, x, y, pressed, ok := decode_mouse_input()

    if !ok do return false

    // Extra button state.
    button := Mouse_Button(state & 0b11)
    if (state & 0b1000000) != 0 {
        button = Mouse_Button(4 + (state - 0b1000000))
    }
    button_modifiers := transmute(Modifiers)cast(u8)((state >> 2) & 0b111)

    // Append event to queue
    ev := Mouse_Event {
        button    = button,
        modifiers = button_modifiers,
        pressed   = pressed,
        position  = {x, y},
    }
    queue.append(&_events, ev)

    return true

    decode_mouse_input :: proc() -> (state, x, y: int, pressed, ok: bool) {

        @(static) buffer: [16]byte

        SEPARATOR :: ';'

        // esc [ < {button};{Px};{Py}m (released)
        // esc [ < {button};{Px};{Py}M (pressed)

        // Ensure the input looks like mouse input.
        if input_available() < 3 do return
        if !input_starts_with("\e[<") do return

        start: int
        sep: int

        // Extract {button} value.
        sep = input_index(sep, SEPARATOR)
        if sep == -1 do return
        state_bytes := input_copy(buffer[:], 3, sep)
        state, _ = strconv.parse_int(string(state_bytes))

        sep += 1 // skip separator
        start = sep

        // Extract {Px} value.
        sep = input_index(sep, SEPARATOR)
        if sep == -1 do return
        x_bytes := input_copy(buffer[:], start, sep - start)
        x, _ = strconv.parse_int(string(x_bytes))

        sep += 1 // skip separator
        start = sep

        // Extract {Py} value.
        sep = input_index(sep, 'm', 'M')
        if sep == -1 do return
        y_bytes := input_copy(buffer[:], start, sep - start)
        y, _ = strconv.parse_int(string(y_bytes))

        // Determine if pressed 'M' or realsed 'm'
        pressed = input_get(sep) == 'M'

        // Mouse event parsed, consume characters.
        input_consume(sep + 1)

        ok = true
        return
    }
}

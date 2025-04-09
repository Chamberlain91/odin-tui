package term

import "core:container/queue"
import "core:fmt"
import "core:os"

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
    write(enable ? "\e[?47h" : "\e[?47l")
}

enable_mouse :: proc(enable := true) {
    write(enable ? "\e[?1003h" : "\e[?1003l") // ANY EVENT TRACKING
    write(enable ? "\e[?1006h" : "\e[?1006l") // SGR EXT TRACKING
}

show_cursor :: proc(visible := true) {
    write(visible ? "\e[?25h" : "\e[?25l")
}

process_input :: proc() {
    _process_input()
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
    writef("\e[%d;%dH", pos.y, pos.x)
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
    // TODO whole screen
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
    writef("\e[%vm", 30 + int(color))
}

set_background_color :: proc(color: Color) {
    writef("\e[%vm", 40 + int(color))
}

// TODO: Text attributes?

reset_color :: proc() {
    set_foreground_color(.Default)
    set_background_color(.Default)
}

write :: proc(args: ..any, sep := " ", flush := true) {
    fmt.fprint(os.stdout, ..args, sep = sep, flush = flush)
}

writef :: proc(str: string, args: ..any, flush := true) {
    fmt.fprintf(os.stdout, str, ..args, flush = flush)
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
    is_printable: bool,
    key:          Key,
    str:          string,
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
}

Modifier :: enum u8 {
    Shift,
    Alt,
    Ctrl,
}

Modifiers :: bit_set[Modifier;u8]

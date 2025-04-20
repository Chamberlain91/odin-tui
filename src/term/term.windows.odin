#+build windows
#+private
package term

import "base:runtime"
import "core:c/libc"
import "core:container/queue"
import "core:log"
import "core:os"
import win "core:sys/windows"
import "core:unicode/utf16"

prev_out_codepage: win.CODEPAGE
prev_out_mode: win.DWORD

prev_in_codepage: win.CODEPAGE
prev_in_mode: win.DWORD

_raw_mode: bool

_initialize :: proc() {

    _enter_raw_mode()

    _enter_raw_mode :: proc() {

        _xterm_escape_alt_sequences(true)
        _xterm_alternate_keymap(true)
        _xterm_bracket_paste(true)

        // Try to ensure that the raw
        libc.atexit(_exit_raw_mode)

        win.GetConsoleMode(win.HANDLE(os.stdout), &prev_out_mode)
        prev_out_codepage = win.GetConsoleOutputCP()

        win.GetConsoleMode(win.HANDLE(os.stdin), &prev_in_mode)
        prev_in_codepage = win.GetConsoleCP()

        // Configure new output mode.
        out_mode := prev_out_mode
        set(&out_mode, win.DISABLE_NEWLINE_AUTO_RETURN, true)
        set(&out_mode, win.ENABLE_VIRTUAL_TERMINAL_PROCESSING, true) // Enable ANSI
        set(&out_mode, win.ENABLE_PROCESSED_OUTPUT, true) // ???
        if !win.SetConsoleMode(win.HANDLE(os.stdout), out_mode) {
            log.warn("Failed to set console mode on stdout.")
        }

        // Configure new input mode.
        in_mode := prev_in_mode
        set(&in_mode, win.ENABLE_PROCESSED_INPUT, false) // Disables default Ctrl+C and friends
        set(&in_mode, win.ENABLE_ECHO_INPUT, false)
        set(&in_mode, win.ENABLE_LINE_INPUT, false)
        set(&in_mode, win.ENABLE_VIRTUAL_TERMINAL_INPUT, true) // Enables ANSI
        if !win.SetConsoleMode(win.HANDLE(os.stdin), in_mode) {
            log.warn("Failed to set console mode on stdin.")
        }

        _raw_mode = true

        win.SetConsoleOutputCP(.UTF8)
        win.SetConsoleCP(.UTF8)

        set :: proc(mode: ^u32, flag: u32, enable: bool) {
            if enable do mode^ |= flag
            else do mode^ &= ~flag
        }
    }
}

_shutdown :: proc() {
    _exit_raw_mode()
}

@(private = "file")
_exit_raw_mode :: proc "c" () {

    if !_raw_mode do return

    context = runtime.default_context()

    enable_alternate_screen(false)
    enable_mouse(false)
    show_cursor(true)
    reset_styles()

    _xterm_escape_alt_sequences(false)
    _xterm_alternate_keymap(false)
    _xterm_bracket_paste(false)

    win.SetConsoleMode(win.HANDLE(os.stdout), prev_out_mode)
    win.SetConsoleOutputCP(prev_out_codepage)

    win.SetConsoleMode(win.HANDLE(os.stdin), prev_in_mode)
    win.SetConsoleCP(prev_in_codepage)

    _raw_mode = false
}

_is_tty_in :: proc() -> bool {
    // TODO
    return true
}

_is_tty_out :: proc() -> bool {
    // TODO
    return true
}

// -----------------------------------------------------------------------------

_has_stdin_input :: proc() -> bool {
    n: win.DWORD
    return bool(win.GetNumberOfConsoleInputEvents(win.HANDLE(os.stdin), &n)) && n > 0
}

_read_stdin :: proc() {

    @(static) wbuffer: [512]win.WCHAR
    @(static) buffer: [1024]byte

    i: int
    for &record in read_input_records() {
        #partial switch record.EventType {
        case .KEY_EVENT:
            if ev := &record.Event.KeyEvent; ev.bKeyDown {
                wbuffer[i] = ev.uChar.UnicodeChar
                i += 1
            }
        }
    }

    // Convert UTF16 input text into UTF8 text.
    input := buffer[:utf16.decode_to_utf8(buffer[:], wbuffer[:i])]
    if len(input) > 0 {
        for ch in string(input) {
            queue.append(&_input, ch)
        }
    }

    read_input_records :: proc() -> []win.INPUT_RECORD {
        @(static) records: [16]win.INPUT_RECORD

        if _has_stdin_input() {
            n: win.DWORD
            if win.ReadConsoleInputW(win.HANDLE(os.stdin), raw_data(records[:]), len(records), &n) {
                return records[:n]
            }
        }

        // No input records.
        return {}
    }
}

_terminal_size :: proc() -> [2]int {

    sbi: win.CONSOLE_SCREEN_BUFFER_INFO

    if !win.GetConsoleScreenBufferInfo(win.HANDLE(os.stdout), &sbi) {
        panic("Unable to retrieve terminal size.")
    }

    return [2]int {     //
        int(sbi.srWindow.Bottom - sbi.srWindow.Top) + 1,
        int(sbi.srWindow.Right - sbi.srWindow.Left) + 1,
    }
}

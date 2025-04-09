#+build !windows
#+private
package term

import "base:runtime"
import "core:c"
import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sys/posix"

_original_term: posix.termios

_initialize :: proc() {

    posix.setbuf(posix.stdout, nil)

    _set_raw_mode()

    posix.atexit(_at_exit)

    _set_raw_mode :: proc() {

        // Get current terminal attributes.
        if posix.tcgetattr(posix.STDIN_FILENO, &_original_term) == .FAIL {
            panic("Unable to get terminal attributes.")
        }

        term := _original_term
        term.c_iflag -= {.IGNBRK, .BRKINT, .PARMRK, .ISTRIP, .INLCR, .IGNCR, .ICRNL, .IXON}
        term.c_oflag -= {.OPOST}
        term.c_cflag += {.CS8}
        term.c_lflag -= {.ECHO, .ECHONL, .ICANON, .ISIG, .IEXTEN}

        term.c_cc[.VMIN] = 0
        term.c_cc[.VTIME] = 0

        if posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &term) == .FAIL {
            panic("Unable to set new terminal attributes.")
        }

        fmt.print("\e[?1049h")
        fmt.print("\e[0m") // ??
        fmt.print("\e[2J") // clear screen?
        fmt.print("\e[?1015h")
    }
}

_shutdown :: proc() {
    // TODO
}

_at_exit :: proc "c" () {
    context = runtime.default_context()

    fmt.print("\e[0m")
    fmt.print("\e[2J")
    fmt.print("\e[?1049l")
    fmt.print("\e[?1015l")
    enable_mouse(false)
    show_cursor(true)

    posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &_original_term)
}

_is_tty_in :: proc() -> bool {
    return cast(bool)posix.isatty(posix.STDIN_FILENO)
}

_is_tty_out :: proc() -> bool {
    return cast(bool)posix.isatty(posix.STDOUT_FILENO)
}

_process_input :: proc() {

    @(static) buffer: [1024]byte
    length: int

    for true {

        if n, err := os.read(os.stdin, buffer[length:length + 1]); err == nil && n > 0 {
            ch := buffer[length]

            if ch == 0x1C {     // ctrl+backslash to exit
                os.exit(0)
            }

            length += 1
        } else do break
    }

    // No input to process.
    if length == 0 do return

    // Get slice of actual input
    input := buffer[:length]

    // Appears to be a mouse event
    if strings.starts_with(string(input), "\e[<") {
        if _process_mouse_input(input[3:]) {
            return
        }
    }

    fmt.printf("{:x}: {}\r\n", input, string(input))

    if input[0] == '\e' && length > 1 {
        // ...
    }
}

_process_mouse_input :: proc(input: []byte) -> bool {

    SEPARATOR :: 0x3B

    parse := input[:]
    s0 := slice.linear_search(parse, SEPARATOR) or_return

    // Extra button state.
    button_state, _ := strconv.parse_uint(string(parse[:s0]))
    button := Mouse_Button(button_state & 0b11)
    if (button_state & 0b1000000) != 0 {
        button = Mouse_Button(4 + (button_state - 0b1000000))
    }
    button_modifiers := transmute(Modifiers)cast(u8)((button_state >> 2) & 0b111)

    parse = parse[s0 + 1:]
    s1 := slice.linear_search(parse, SEPARATOR) or_return

    // Extract coordinate state.
    x, _ := strconv.parse_int(string(parse[:s1]))
    y, _ := strconv.parse_int(string(parse[s1 + 1:len(parse) - 1]))

    // Determine 'm' or 'M' for pressed state.
    is_pressed := parse[len(parse) - 1] == 'M'

    // Append event to queue
    ev := Mouse_Event {
        button    = button,
        modifiers = button_modifiers,
        pressed   = is_pressed,
        position  = {x, y},
    }
    queue.append(&_events, ev)

    return true
}

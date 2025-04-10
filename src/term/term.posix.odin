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

    _set_raw_mode()

    posix.atexit(proc "c" () {
        context = runtime.default_context()

        erase_screen()
        reset_color()
        enable_alternate_screen(false)
        enable_mouse(false)
        show_cursor(true)

        fmt.print("\a")

        posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &_original_term)
    })

    erase_screen()
    reset_color()
    enable_alternate_screen()
    set_cursor_position({0, 0})
    enable_mouse()

    _set_raw_mode :: proc() {

        posix.setbuf(posix.stdout, nil)

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
    }
}

_shutdown :: proc() {
    // TODO
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

            if ch == '`' {     // tilde to exit
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

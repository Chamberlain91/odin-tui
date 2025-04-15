#+build !windows
#+private
package term

import "base:runtime"
import "core:c"
import "core:container/queue"
import "core:os"
import "core:sys/posix"

_original_term: posix.termios
_raw_mode: bool

_initialize :: proc() {

    _enter_raw_mode()

    _enter_raw_mode :: proc() {

        posix.atexit(_exit_raw_mode)

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

        _raw_mode = true
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
    reset()

    posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &_original_term)

    _raw_mode = false
}

_is_tty_in :: proc() -> bool {
    return cast(bool)posix.isatty(posix.STDIN_FILENO)
}

_is_tty_out :: proc() -> bool {
    return cast(bool)posix.isatty(posix.STDOUT_FILENO)
}

_has_stdin_input :: proc() -> bool {

    TIMEOUT_MS :: 1

    rdfs: posix.fd_set
    posix.FD_ZERO(&rdfs)
    posix.FD_SET(posix.STDIN_FILENO, &rdfs)

    tv: posix.timeval
    tv.tv_usec = posix.suseconds_t(TIMEOUT_MS * 1000)

    return posix.select(1, &rdfs, nil, nil, &tv) == 1
}

_read_stdin :: proc() {

    @(static) buffer: [1024]byte

    n, err := os.read(os.stdin, buffer[:])
    if err == nil && n > 0 {
        for ch in string(buffer[:n]) {
            queue.append(&_input, ch)
        }
    }
}

_terminal_size :: proc() -> [2]int {
    ws: winsize
    if ioctl(posix.STDOUT_FILENO, TIOCGWINSZ, &ws) != 0 {
        panic("Unable to retrieve terminal size.")
    }
    return {int(ws.ws_col), int(ws.ws_row)}
}

// -----------------------------------------------------------------------------

foreign import _libc "system:c"
@(default_calling_convention = "c")
foreign _libc {
    ioctl :: proc(fs: c.int, request: c.int, #c_vararg args: ..any) -> c.int ---
}

TIOCGWINSZ :: 0x5413

winsize :: struct {
    ws_row:    u16, // rows, in characters
    ws_col:    u16, // columns, in characters
    ws_xpixel: u16, // horizontal pixels
    ws_ypixel: u16, // vertical pixels
}

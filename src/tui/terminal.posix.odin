#+build !windows
#+private
package oak_tui

import "core:c"
import "core:fmt"
import "core:os"
import "core:sys/posix"

prev_term: posix.termios

@(init, private = "file")
_init_terminal :: proc() {

    // Get current terminal attributes.
    if posix.tcgetattr(posix.STDIN_FILENO, &prev_term) == .FAIL {
        panic("Unable to get terminal attributes.")
    }

    // Reset to the original attributes at the end of the program.
    posix.atexit(proc "c" () {
        posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &prev_term)
    })

    term := prev_term
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

_read :: proc() -> (int, bool) {
    n, err := os.read(os.stdin, _buffer[:])
    if err == nil {
        return n, true
    } else {
        return 0, false
    }
}

_window_size :: proc() -> [2]int {
    ws: winsize
    if ioctl(posix.STDOUT_FILENO, TIOCGWINSZ, &ws) != 0 {
        panic("Unable to retrieve terminal size.")
    }
    return [2]int {     //
        int(ws.ws_col),
        int(ws.ws_row),
    }
}

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

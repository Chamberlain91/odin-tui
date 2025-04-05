#+build !windows
#+private
package oak_tui

import "core:c"
import "core:sys/posix"

original_mode: posix.termios

@(init, private = "file")
_init_terminal :: proc() {

    // Get current terminal attributes.
    if posix.tcgetattr(posix.STDIN_FILENO, &original_mode) == .FAIL {
        panic("Unable to get terminal attributes.")
    }

    // Reset to the original attributes at the end of the program.
    posix.atexit(proc "c" () {
        posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &original_mode)
    })

    mode := original_mode
    mode.c_lflag -= {.ECHO, .ICANON}
    if posix.tcsetattr(posix.STDIN_FILENO, .TCSANOW, &mode) == .FAIL {
        panic("Unable to set new terminal attributes.")
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

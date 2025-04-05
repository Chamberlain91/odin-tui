#+build windows
#+private
package oak_tui

import "core:c/libc"
import "core:os"
import win "core:sys/windows"

prev_out_mode: win.DWORD
prev_in_mode: win.DWORD

@(init, private = "file")
_init_terminal :: proc() {

    win.GetConsoleMode(win.HANDLE(os.stdout), &prev_out_mode)
    win.GetConsoleMode(win.HANDLE(os.stdin), &prev_in_mode)

    // Configure new output mode.
    out_mode := prev_out_mode
    out_mode &= ~win.ENABLE_WRAP_AT_EOL_OUTPUT // Disables line wrapping when writing text
    out_mode |= win.ENABLE_VIRTUAL_TERMINAL_PROCESSING // Enable ANSI

    // Configure new input mode.
    in_mode := prev_in_mode
    in_mode &= ~win.ENABLE_ECHO_INPUT // Disables echoing input to the screen.
    in_mode &= ~win.ENABLE_LINE_INPUT // Disables line buffering input.
    in_mode &= ~win.ENABLE_PROCESSED_INPUT // Disables handling Ctrl+C and friends
    in_mode |= win.ENABLE_VIRTUAL_TERMINAL_INPUT // Enables ANSI
    in_mode |= win.ENABLE_WINDOW_INPUT // Enables window events in STDIN 

    win.SetConsoleMode(win.HANDLE(os.stdout), out_mode)
    win.SetConsoleMode(win.HANDLE(os.stdin), in_mode)

    win.SetConsoleOutputCP(.UTF8)
    win.SetConsoleCP(.UTF8)

    // Reset to the original attributes at the end of the program.
    libc.atexit(proc "c" () {
        win.SetConsoleMode(win.HANDLE(os.stdout), prev_out_mode)
        win.SetConsoleMode(win.HANDLE(os.stdin), prev_in_mode)
    })
}

_window_size :: proc() -> [2]int {

    sbi: win.CONSOLE_SCREEN_BUFFER_INFO

    if !win.GetConsoleScreenBufferInfo(win.HANDLE(os.stdout), &sbi) {
        panic("Unable to retrieve terminal size.")
    }

    return [2]int {     //
        int(sbi.srWindow.Bottom - sbi.srWindow.Top) + 1,
        int(sbi.srWindow.Right - sbi.srWindow.Left) + 1,
    }
}

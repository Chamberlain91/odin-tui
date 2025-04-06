#+build windows
#+private
package oak_tui

import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import win "core:sys/windows"
import "core:unicode/utf16"

prev_out_mode: win.DWORD
prev_in_mode: win.DWORD

@(init, private = "file")
_init_terminal :: proc() {

    win.GetConsoleMode(win.HANDLE(os.stdout), &prev_out_mode)
    win.GetConsoleMode(win.HANDLE(os.stdin), &prev_in_mode)

    // Reset to the original attributes at the end of the program.
    libc.atexit(proc "c" () {
        win.SetConsoleMode(win.HANDLE(os.stdout), prev_out_mode)
        win.SetConsoleMode(win.HANDLE(os.stdin), prev_in_mode)
    })

    // Configure new output mode.
    out_mode := prev_out_mode
    enable(&out_mode, win.DISABLE_NEWLINE_AUTO_RETURN)
    enable(&out_mode, win.ENABLE_VIRTUAL_TERMINAL_PROCESSING) // Enable VT100 codes
    enable(&out_mode, win.ENABLE_PROCESSED_OUTPUT) // ???

    if !win.SetConsoleMode(win.HANDLE(os.stdout), out_mode) {
        panic("Failed to set terminal output mode")
    }

    // Configure new input mode.
    in_mode := prev_in_mode
    disable(&in_mode, win.ENABLE_PROCESSED_INPUT) // Disables default Ctrl+C and friends
    disable(&in_mode, win.ENABLE_ECHO_INPUT)
    disable(&in_mode, win.ENABLE_LINE_INPUT)
    enable(&in_mode, win.ENABLE_VIRTUAL_TERMINAL_INPUT) // Enables VT100
    enable(&in_mode, win.ENABLE_WINDOW_INPUT)
    enable(&in_mode, win.ENABLE_MOUSE_INPUT)
    if !win.SetConsoleMode(win.HANDLE(os.stdin), in_mode) {
        panic("Failed to set terminal input mode")
    }

    win.SetConsoleOutputCP(.UTF8)
    win.SetConsoleCP(.UTF8)

    fmt.eprint(cast(rune)0)
    fmt.print(cast(rune)0)

    enable :: proc(mode: ^u32, flag: u32) {
        mode^ |= flag
    }

    disable :: proc(mode: ^u32, flag: u32) {
        mode^ &= ~flag
    }
}

_read :: proc() -> (int, bool) {

    nEvents: u32
    if !win.GetNumberOfConsoleInputEvents(win.HANDLE(os.stdin), &nEvents) {
        return 0, false
    }

    if nEvents > 0 {

        input_records: [128]win.INPUT_RECORD
        if !win.ReadConsoleInputW(win.HANDLE(os.stdin), raw_data(input_records[:]), 32, &nEvents) {
            return 0, false
        }

        wbuffer: [128]win.WCHAR

        wb := 0
        for i: u32 = 0; i < nEvents; i += 1 {
            #partial switch input_records[i].EventType {
            case .KEY_EVENT:
                if ev := &input_records[i].Event.KeyEvent; ev.bKeyDown {
                    wbuffer[wb] = ev.uChar.UnicodeChar
                    wb += 1
                }
            }
        }

        // Copy UTF16 input text into the UTF8 _buffer.
        n := utf16.decode_to_utf8(_buffer[:], wbuffer[:wb])

        return n, true
    }

    // No input
    return 0, false
}

foreign import kernel32 "system:Kernel32.lib"
@(default_calling_convention = "system")
foreign kernel32 {
    ReadConsoleA :: proc(hConsoleInput: win.HANDLE, lpBuffer: win.LPVOID, nNumberOfCharsToRead: win.DWORD, lpNumberOfCharsRead: win.LPDWORD, pInputControl: win.PCONSOLE_READCONSOLE_CONTROL) -> win.BOOL ---
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

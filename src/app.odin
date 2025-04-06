package tui_app

@(require) import "core:fmt"
@(require) import "core:log"
@(require) import "core:strings"
import "core:time"
@(require) import "core:unicode"
import "tui"

main :: proc() {

    context.logger = tui.create_scoped_logger()
    when ODIN_DEBUG {
        context.allocator = tui.create_scoped_tracking_allocator()
    }

    tui.scoped_tui_application("Hello TUI")

    // tui.enable_mouse_input(true)
    // tui.show_cursor(false)

    fmt.printf("terminal size: {}", tui.window_size())
    tui.cursor_move(0, 1)

    loop: for true {

        input, input_ok := tui.read()

        if !input_ok || len(input) == 0 {
            time.accurate_sleep(10 * time.Millisecond) // ~100fps
            fmt.print(".")
            continue
        }

        fmt.printf("<<{}>>", input)

        if input[0] == ESCAPE {

            if len(input) > 1 {
                // TODO: An eascape sequence has been input (mouse, home key, etc)
                fmt.printf("<escape sequence:{}>", len(input))
            } else {
                // TODO: User has pressed the escape key.
                fmt.printf("<escape key>: {}", tui.get_cursor_position())
            }

        } else {

            // Quit
            if input[0] == 'q' {
                break loop
            }

            switch input[0] {
            case KEY_ENTER:
                fmt.print("<return key>")
                continue
            case KEY_CTRL_C:
                fmt.print("<ctrl+c>")
                continue
            case KEY_CTRL_X:
                fmt.print("<ctrl+x>")
                continue
            case KEY_ARROW_LEFT:
                fmt.print("<arrow left>")
                continue
            case KEY_ARROW_UP:
                fmt.print("<arrow up>")
                continue
            case KEY_ARROW_RIGHT:
                fmt.print("<arrow right>")
                continue
            case KEY_ARROW_DOWN:
                fmt.print("<arrow down>")
                continue
            }

            for ch in input {
                // TODO: The user has typed a single character.
                if unicode.is_print(ch) do tui.write(ch)
                else {
                    fmt.printf("|{:d}|", ch)
                }
            }
        }
    }
}

ESCAPE :: 0x1B
KEY_BACKSPACE :: 0x7F
KEY_ENTER :: 0xD

KEY_CTRL_X :: 0x18
KEY_CTRL_C :: 0x03

KEY_ARROW_UP :: 0x41
KEY_ARROW_DOWN :: 0x42
KEY_ARROW_RIGHT :: 0x43
KEY_ARROW_LEFT :: 0x44

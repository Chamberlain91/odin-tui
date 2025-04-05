package tui_app

@(require) import "core:fmt"
@(require) import "core:log"
import "tui"

main :: proc() {

    context.logger = tui.create_scoped_logger()
    when ODIN_DEBUG {
        context.allocator = tui.create_scoped_tracking_allocator()
    }

    tui.scoped_tui_application("Hello TUI")
    tui.show_cursor(false)

    tui.write("this is some text\non some other lines\nbut\nI don't really care\n")
    fmt.printfln("Terminal window: {}", tui.window_size())

    loop: for true {
        input := tui.read_input()
        fmt.printfln("input was: '{}'", input)
        switch input {
        case "q":
            break loop
        }
    }
}

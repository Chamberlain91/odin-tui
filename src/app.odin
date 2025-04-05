package tui_app

@(require) import "core:fmt"
@(require) import "core:log"
import "tui"

main :: proc() {

    context.logger = tui.create_scoped_logger()
    when ODIN_DEBUG {
        context.allocator = tui.create_scoped_tracking_allocator()
    }

    tui.enable_alt_buffer()
    defer tui.disable_alt_buffer()

    tui.erase_screen()
    tui.cursor_move_home()

    tui.write("this is some text\non some other lines\nbut\nI don't really care\n")

    loop: for true {
        input := tui.read_input()
        fmt.printfln("input was: '{}'", input)
        switch input {
        case "q":
            break loop
        }
    }
}

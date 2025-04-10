package app

@(require) import "core:fmt"
import "core:log"
import "core:os"
import "core:time"
import "term"

main :: proc() {

    when ODIN_DEBUG {
        context.allocator = term.create_scoped_tracking_allocator()
        context.temp_allocator = term.create_scoped_tracking_allocator(context.temp_allocator)
    }
    context.logger = term.create_scoped_logger()

    // This application is useless unless ran interactively.
    if !term.is_interactive() {
        fmt.eprintln("This application does not support non-interactive mode.")
        os.exit(1)
    }

    term.initialize()
    defer term.shutdown()

    loop: for true {
        defer free_all(context.temp_allocator)
        defer time.sleep(time.Millisecond) // stay cool

        // Handle events for this iteration.
        term.process_input()

        // Chew threw event queue.
        for term.has_event() {

            extra: string

            switch ev in term.get_event() or_break {
            case term.Mouse_Event:
                term.set_cursor_position(ev.position)
                extra = fmt.tprint(ev)
            case term.Size_Event:
                extra = fmt.tprint(ev)
            case term.Key_Event:
                if ev.key == .Escape || ev.ch == 'q' {
                    break loop
                }
                extra = fmt.tprint(ev)
            }

            cursor_pos := term.cursor_position()

            term.set_foreground_color(.Yellow)
            fmt.printf("x: %i, y: %i", expand_values(cursor_pos))

            if len(extra) > 0 {
                term.set_foreground_color(.Cyan)
                term.set_cursor_position(cursor_pos + {0, 1})
                fmt.printf("event: %v", extra)
            }

            term.set_foreground_color(.Default)
            term.set_cursor_position(cursor_pos)
        }

        // TODO: Make zero oriented
        term.set_cursor_position({1, 1})
        fmt.printf("Current time: {}:{}:{}", time.clock(time.now()))
    }
}

// package tui_app

// @(require) import "core:fmt"
// @(require) import "core:log"
// import "core:os"
// @(require) import "core:strings"
// import "core:time"
// @(require) import "core:unicode"
// import "tui"

// // posix.ctermid
// // posix.isatty
// // posix.ttyname_r

// // https://github.com/dankamongmen/notcurses/
// // Not curses seems to build an enum mapping of escapes to their character strings per "terminal"
// // Then it uses terminfo to detect which table to use. 
// // - Windows is either msterminal or mintty, but one table...?

// main :: proc() {

//     context.logger = tui.create_scoped_logger()
//     when ODIN_DEBUG {
//         context.allocator = tui.create_scoped_tracking_allocator()
//         context.temp_allocator = tui.create_scoped_tracking_allocator(context.temp_allocator)
//     }

//     // This application is useless unless ran interactively.
//     if !tui.is_interactive() {
//         fmt.eprintln("This application does not support non-interactive mode.")
//         os.exit(1)
//     }

//     // ...
//     tui.init_terminal("Hello TUI")
//     defer tui.shutdown_terminal()

//     tui.enable_alt_buffer(true)
//     // tui.enable_mouse_input(true)
//     // tui.show_cursor(false)
//     tui.cursor_move(0, 0)

//     fmt.printf("terminal size: {}", tui.window_size())
//     tui.cursor_move(0, 1)

//     loop: for true {

//         // Process any input.
//         tui.process_input()

//         // No input, do nothing but wait a bit.
//         if tui.input_available() == 0 {
//             time.accurate_sleep(20 * time.Millisecond) // ~50fps
//             continue
//         }

//         // TODO: Change read() to a read/consume pattern..?
//         // input := tui.input()
//         // tui.consume()
//         // TODO: or... just one character a time?
//         {
//             // tui.show_cursor(false)
//             // cur_pos := tui.get_cursor_position()
//             // tui.cursor_move(0, 0)
//             // fmt.printf("terminal size: {}", tui.window_size())
//             // tui.cursor_move(0, 1)
//             // fmt.printf("cursor position: {}\n\r", cur_pos)
//             // if cur_pos.x >= 0 {
//             //     tui.cursor_move(expand_values(cur_pos))
//             // }
//             // tui.show_cursor(true)
//         }

//         switch tui.input_peek() {
//         case 'q':
//             fmt.print("<q>")
//             break loop
//         case KEY_ESCAPE:
//             fmt.print("<escape key>")
//             break loop
//         case KEY_ENTER:
//             fmt.print("<return key>")
//         case KEY_BACKSPACE:
//             fmt.print("<backspace key>")
//         case KEY_CTRL_C:
//             fmt.print("<ctrl+c>")
//         case KEY_CTRL_X:
//             fmt.print("<ctrl+x>")
//         case KEY_ARROW_LEFT:
//             fmt.print("<arrow left>")
//         case KEY_ARROW_UP:
//             fmt.print("<arrow up>")
//         case KEY_ARROW_RIGHT:
//             fmt.print("<arrow right>")
//         case KEY_ARROW_DOWN:
//             fmt.print("<arrow down>")
//         }

//         if tui.input_available() > 1 {
//             // TODO: An escape sequence has been input (mouse, home key, etc)
//             fmt.print("<")
//             for i in 0 ..< tui.input_available() {
//                 if i > 0 do fmt.print(":")
//                 fmt.printf("{:x}", tui.input_peek(i))
//             }
//             fmt.print(">")
//         }

//         for ch in tui.input_read(tui.input_available()) {
//             // TODO: The user has typed a single character.
//             if unicode.is_print(ch) do fmt.print(ch)
//             else {
//                 fmt.print(ch, flush = false)
//             }
//         }
//         fmt.print(flush = true)

//         // Dispose all temporary allocations.
//         free_all(context.temp_allocator)
//     }
// }

// ESCAPE :: 0x1B

// KEY_ESCAPE :: ESCAPE
// KEY_BACKSPACE :: 0x7F
// KEY_ENTER :: 0xD

// KEY_CTRL_Z :: 0x1a
// KEY_CTRL_V :: 0x16
// KEY_CTRL_X :: 0x18
// KEY_CTRL_C :: 0x03

// KEY_ARROW_UP :: 0x41
// KEY_ARROW_DOWN :: 0x42
// KEY_ARROW_RIGHT :: 0x43
// KEY_ARROW_LEFT :: 0x44

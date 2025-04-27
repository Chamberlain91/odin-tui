# Odin TUI (Terminal User Interface for Odin)

This library is WIP.

This implements a terminal control library using ANSI/VT100 escape codes that runs in Windows and Linux. Functional on Windows Terminal, Xterm, Konsole, and VS Code integrated terminal. 

Note: It might not actually be VT100 compliant, it might use other features I'm not an expert with escape codes.

```odin
package app

import "../tui" // or however you want to include it

main :: proc() {

    tui.initialize()
    defer tui.shutdown()

    tui.enable_alternate_screen(true)
    tui.show_cursor(false)

    main_loop: for {

        for do switch ev in tui.get_event() or_break {
        case tui.Size_Event:
            // Handle resize
        case tui.Mouse_Event:
          // Handle mouse input
        case tui.Key_Event:
            if ev.control == .Sig_Interrupt do break main_loop
            if ev.key == .Escape do break main_loop
            if ev.str == "q" do break main_loop
        case tui.Paste_Event:
          // Handle bracked paste
        }

        // Prevent looping too tightly.
        time.sleep(time.Millisecond)
    }
}
```

## How to run the example?

```odin
cd example
odin run .
```

Use `w`, `a`, `s`, and `d` to move. Its not a good game of snake, you can't crash into yourself... but it does show the library doing its thing.

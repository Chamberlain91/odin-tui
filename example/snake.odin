package snake_tui

import "../tui"
import "core:math/rand"
import "core:time"

Snake_Dir :: enum {
    East,
    South,
    West,
    North,
}

main :: proc() {

    tui.initialize()
    defer tui.shutdown()

    game_size: [2]int = {50, 25}
    game_offset: [2]int

    tui.enable_alternate_screen(true)
    tui.show_cursor(false)

    canvas := tui.canvas_create(game_size)
    defer tui.canvas_destroy(canvas)

    food := [2]int{2, 2}

    snake_dir := Snake_Dir.East
    next_snake_dir := Snake_Dir.East
    snake: [dynamic][2]int
    append(&snake, food)

    last_tick := time.tick_now()

    game_loop: for {

        for do #partial switch ev in tui.get_event() or_break {
        case tui.Size_Event:
            game_offset = (ev.size - game_size) / 2
            tui.erase_screen()
        case tui.Key_Event:
            if ev.control == .Sig_Interrupt do break game_loop
            if ev.key == .Escape do break game_loop
            if ev.str == "q" do break game_loop
            switch ev.str {
            case "w":
                if snake_dir != .South do next_snake_dir = .North
            case "a":
                if snake_dir != .East do next_snake_dir = .West
            case "s":
                if snake_dir != .North do next_snake_dir = .South
            case "d":
                if snake_dir != .West do next_snake_dir = .East
            }
        }

        // ....
        if tui.size().x < game_size.x || tui.size().y < game_size.y {
            tui.erase_screen()
            tui.set_cursor_position({0, 0})
            tui.printf("Terminal too small, must be {} (current size {})", game_size + {1, 1}, tui.size())
            time.sleep(time.Millisecond * 100)
            continue game_loop
        }

        // Clear the canvas and surround with a box drawing frame.
        tui.canvas_clear(canvas)
        tui.canvas_box_rect(canvas, {0, 0}, game_size - {1, 1}, .White)

        // Draw food.
        tui.canvas_set_bg_color(canvas, food, .Green)

        // Draw snake.
        for s in snake {
            tui.canvas_set_bg_color(canvas, s, .Red)
        }

        // Enough time has pased to advance the snake.
        if time.tick_since(last_tick) > (time.Millisecond * 66) {
            last_tick = time.tick_now()

            // Get the current position of the snake head.
            snake_pos := snake[len(snake) - 1]

            if snake_pos == food {
                // Food was eaten, randomize its position.
                // This causes the snake to get longer since we do not trim the tail.
                // Note: This is a bad impl, since it could place the food overlapping the snake
                food.x = rand.int_max(game_size.x - 1)
                food.y = rand.int_max(game_size.y - 1)
            } else {
                // No food was eaten, trim the tail.
                pop_front(&snake)
            }

            // Update the snake dir to reflect user input.
            snake_dir = next_snake_dir

            // Advance the snake.
            switch snake_dir {
            case .East:
                snake_pos.x += 1
                if snake_pos.x >= game_size.x do snake_pos.x = 0
            case .South:
                snake_pos.y += 1
                if snake_pos.y >= game_size.y do snake_pos.y = 0
            case .West:
                snake_pos.x -= 1
                if snake_pos.x < 0 do snake_pos.x = game_size.x - 1
            case .North:
                snake_pos.y -= 1
                if snake_pos.y < 0 do snake_pos.y = game_size.y - 1
            }

            // TODO: This is where one may detect if the snake crashed into itself

            // Append the new head position.
            append(&snake, snake_pos)
        }

        // Present canvas to the screen.
        tui.canvas_blit(canvas, game_offset)

        // Prevent looping too tightly.
        time.sleep(time.Millisecond)
    }
}

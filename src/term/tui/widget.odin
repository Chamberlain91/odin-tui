package oak_tui

import term ".."
import "core:fmt"
import "core:slice"

Widget :: struct {
    position: [2]int,
    size:     [2]int,
    variant:  union {
        ^Window,
    },
}

Window :: struct {
    using _: Widget,
    title:   string,
}

Canvas :: struct {
    storage: []rune,
    size:    [2]int,
}

canvas_create :: proc(size: [2]int) -> Canvas {
    canvas: Canvas = {
        storage = make([]rune, size.x * size.y),
        size    = size,
    }
    return canvas
}

canvas_destroy :: proc(canvas: Canvas) {
    delete(canvas.storage)
}

canvas_get_ptr :: proc(canvas: Canvas, position: [2]int) -> ^rune {
    return &canvas.storage[position.x + (position.y * canvas.size.x)]
}

canvas_get :: proc(canvas: Canvas, position: [2]int) -> rune {
    return canvas_get_ptr(canvas, position)^
}

canvas_set :: proc(canvas: Canvas, position: [2]int, glyph: rune) {
    canvas_get_ptr(canvas, position)^ = glyph
}

// Fill the canvas with ' ' rune.
canvas_clear :: proc(canvas: Canvas) {
    slice.fill(canvas.storage, ' ')
}

canvas_resize :: proc(canvas: ^Canvas, size: [2]int, blit := true) {

    new_canvas := canvas_create(size)

    if blit {
        for y in 0 ..< min(canvas.size.y, size.y) {
            for x in 0 ..< min(canvas.size.x, size.x) {
                canvas_set(new_canvas, {x, y}, canvas_get(canvas^, {x, y}))
            }
        }
    }

    canvas_destroy(canvas^)
    canvas^ = new_canvas
}

canvas_blit :: proc(canvas: Canvas) {

    term.save_cursor()
    defer term.restore_cursor()

    for y in 0 ..< canvas.size.y {
        term.set_cursor_position({0, y})
        for x in 0 ..< canvas.size.x {
            fmt.print(canvas_get(canvas, {x, y}), flush = false)
        }
        term.move_cursor_next_line()
    }

    fmt.print(flush = true)
}

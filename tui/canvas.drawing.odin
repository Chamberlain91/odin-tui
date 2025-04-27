package odin_tui

// Draws a box drawing rect.
canvas_box_rect :: proc(canvas: Canvas, position: [2]int, size: [2]int, color: Color) {

    for y in 1 ..< size.y {

        e0 := position + {0, y}
        canvas_set_fg_color(canvas, e0, color)
        canvas_set(canvas, e0, '│')

        e1 := position + {size.x, y}
        canvas_set_fg_color(canvas, e1, color)
        canvas_set(canvas, e1, '│')
    }

    for x in 1 ..< size.x {

        e0 := position + {x, 0}
        canvas_set_fg_color(canvas, e0, color)
        canvas_set(canvas, e0, '─')

        e1 := position + {x, size.y}
        canvas_set_fg_color(canvas, e1, color)
        canvas_set(canvas, e1, '─')
    }

    TL := position
    TR := position + {size.x, 0}
    BR := position + size
    BL := position + {0, size.y}

    canvas_set_fg_color(canvas, TL, color)
    canvas_set(canvas, TL, '┌')

    canvas_set_fg_color(canvas, TR, color)
    canvas_set(canvas, TR, '┐')

    canvas_set_fg_color(canvas, BR, color)
    canvas_set(canvas, BR, '┘')

    canvas_set_fg_color(canvas, BL, color)
    canvas_set(canvas, BL, '└')
}

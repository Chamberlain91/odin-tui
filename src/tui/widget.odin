package oak_tui

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

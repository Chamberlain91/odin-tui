package term

import "base:runtime"

@(require_results, deferred_in_out = destroy_standard_context)
scoped_standard_context :: proc(allocator := context.allocator, loc := #caller_location) -> runtime.Context {
    context.logger = create_logger()
    when ODIN_DEBUG {
        context.allocator = create_tracking_allocator(context.allocator)
    }
    return context
}

@(private)
destroy_standard_context :: proc(
    allocator := context.allocator,
    loc: runtime.Source_Code_Location,
    ctx: runtime.Context,
) {
    context = ctx
    context.allocator = allocator
    when ODIN_DEBUG {
        destroy_tracking_allocator(ctx.allocator, loc)
    }
    destroy_logger()
}

package term

import "base:runtime"
import "core:log"
import "core:mem"
import "core:mem/virtual"

@(require_results, deferred_out = destroy_tracking_allocator)
create_scoped_tracking_allocator :: proc(backing_allocator := context.allocator) -> runtime.Allocator {
    return create_tracking_allocator(backing_allocator)
}

create_tracking_allocator :: proc(backing_allocator := context.allocator) -> runtime.Allocator {

    track := new(mem.Tracking_Allocator)

    mem.tracking_allocator_init(track, context.allocator)
    return mem.tracking_allocator(track)
}

destroy_tracking_allocator :: proc(tracking_allocator := context.allocator) {

    track := (^mem.Tracking_Allocator)(tracking_allocator.data)
    defer free(track)
    defer mem.tracking_allocator_destroy(track)

    // Display tracking information.
    print_tracking_allocator_info(tracking_allocator)

    if n := len(track.allocation_map); n > 0 {
        log.warnf("== {} allocations not freed ==", n)
        for _, entry in track.allocation_map {
            log.warnf("- {} bytes @ {}", entry.size, entry.location)
        }
    }

    if n := len(track.bad_free_array); n > 0 {
        log.errorf("== {} bad frees ==", n)
        for entry in track.bad_free_array {
            log.errorf("- {} @ {}", entry.memory, entry.location)
        }
    }
}

print_tracking_allocator_info :: proc(tracking_allocator := context.allocator) {

    track := (^mem.Tracking_Allocator)(tracking_allocator.data)

    log.debug("== Tracking Allocator ==")
    log.debugf("current: {:#.1M}", track.current_memory_allocated)
    log.debugf("total:   {:#.1M}", track.total_memory_allocated)
    log.debugf("peak:    {:#.1M}", track.peak_memory_allocated)
}

// Creates an arena allocator with scope limited lifetime.
@(require_results, deferred_out = delete_scoped_arena_allocator)
scoped_arena_allocator :: proc() -> runtime.Allocator {

    arena := new(virtual.Arena)
    if err := virtual.arena_init_growing(arena); err != .None {
        log.panicf("Allocator init error: {}", err)
    }

    return virtual.arena_allocator(arena)
}

@(private = "file")
delete_scoped_arena_allocator :: proc(allocator: runtime.Allocator) {
    arena := (^virtual.Arena)(allocator.data)
    virtual.arena_destroy(arena)
    free(arena)
}

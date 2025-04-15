package term

import "base:runtime"
import "core:log"
import "core:mem"
import "core:mem/virtual"

@(private)
create_tracking_allocator :: proc(backing_allocator: runtime.Allocator) -> runtime.Allocator {
    track := new(mem.Tracking_Allocator)
    mem.tracking_allocator_init(track, backing_allocator)
    return mem.tracking_allocator(track)
}

@(private)
destroy_tracking_allocator :: proc(tracking_allocator: runtime.Allocator, loc := #caller_location) {

    track := (^mem.Tracking_Allocator)(tracking_allocator.data)
    defer free(track)
    defer mem.tracking_allocator_destroy(track)

    report_tracking_allocator(track, loc)
}

@(private)
report_tracking_allocator :: proc(track: ^mem.Tracking_Allocator, loc: runtime.Source_Code_Location) {

    // Report tracking information.
    log.debug("== Allocations ==", location = loc)
    log.debugf("current: {:#.1M}", track.current_memory_allocated, location = loc)
    log.debugf("total:   {:#.1M}", track.total_memory_allocated, location = loc)
    log.debugf("peak:    {:#.1M}", track.peak_memory_allocated, location = loc)

    if n := len(track.allocation_map); n > 0 {
        log.warnf("== {} allocations not freed ==", n, location = loc)
        for _, entry in track.allocation_map {
            log.warnf("- {} bytes @ {}", entry.size, entry.location, location = loc)
        }
    }

    if n := len(track.bad_free_array); n > 0 {
        log.errorf("== {} bad frees ==", n, location = loc)
        for entry in track.bad_free_array {
            log.errorf("- {} @ {}", entry.memory, entry.location, location = loc)
        }
    }
}

// Creates an arena allocator with scope limited lifetime.
@(require_results, deferred_out = destroy_scoped_areana_allocator)
scoped_arena_allocator :: proc() -> runtime.Allocator {

    arena := new(virtual.Arena)
    if err := virtual.arena_init_growing(arena); err != .None {
        log.panicf("Allocator init error: {}", err)
    }

    return virtual.arena_allocator(arena)
}

@(private = "file")
destroy_scoped_areana_allocator :: proc(allocator: runtime.Allocator) {
    arena := (^virtual.Arena)(allocator.data)
    virtual.arena_destroy(arena)
    free(arena)
}

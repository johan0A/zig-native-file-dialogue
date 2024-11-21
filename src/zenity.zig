const std = @import("std");
const Allocator = std.mem.Allocator;

const root = @import("root.zig");

const ZENITY_SEPARATOR = '|';

fn runCommand(alloc: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    var process = std.process.Child.init(argv, alloc);
    process.stdout_behavior = .Pipe;
    try process.spawn();

    const stdout = process.stdout orelse return error.NoStdout;
    const result = try stdout.readToEndAlloc(alloc, std.math.maxInt(usize));
    errdefer alloc.free(result);

    const term = try process.wait();
    if (term != .Exited) {
        return root.DialogueError.OpeningFileDialogueFailed;
    }

    switch (term.Exited) {
        0 => {},
        1 => return &.{},
        else => return root.DialogueError.OpeningFileDialogueFailed,
    }

    return result;
}

pub fn fileDialogue(
    comptime multiple: bool,
    alloc: Allocator,
    config: root.SaveDialogueConfig,
) root.DialogueError!if (multiple) [][]u8 else ?[]u8 {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var args = std.ArrayListUnmanaged([]const u8){};
    try args.appendSlice(arena, &.{ "zenity", "--file-selection" });

    if (multiple)
        try args.append(arena, "--multiple");

    if (config.type == .directory)
        try args.append(arena, "--directory");

    try appendFilterArgs(arena, &args, config.filters);

    const output = runCommand(arena, args.items) catch return root.DialogueError.OpeningFileDialogueFailed;
    var result = std.ArrayListUnmanaged([]u8){};
    errdefer result.deinit(alloc);
    var iter = std.mem.splitScalar(u8, output, '|');

    if (multiple) {
        while (iter.next()) |path| {
            try result.append(alloc, try alloc.dupe(u8, path));
        }
        return try result.toOwnedSlice(alloc);
    } else {
        return try alloc.dupe(u8, iter.next() orelse return null);
    }
}

pub fn saveDialogue(
    alloc: Allocator,
    config: root.SaveDialogueConfig,
) root.DialogueError!?[]u8 {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var args = std.ArrayListUnmanaged([]const u8){};
    try args.appendSlice(arena, &.{ "zenity", "--file-selection", "--save" });

    if (config.placeholder_name.len > 0) {
        var arg = std.ArrayListUnmanaged(u8){};
        try arg.appendSlice(arena, "--filename=");
        try arg.appendSlice(arena, config.placeholder_name);
        try args.append(arena, arg.items);
    }

    if (config.type == .directory)
        try args.append(arena, "--directory");

    try appendFilterArgs(arena, &args, config.filters);

    const output = runCommand(arena, args.items) catch return root.DialogueError.OpeningFileDialogueFailed;
    var iter = std.mem.splitScalar(u8, output, '|');

    return try alloc.dupe(u8, iter.next() orelse return null);
}

fn appendFilterArgs(
    arena: Allocator,
    args: *std.ArrayListUnmanaged([]const u8),
    filters: []const root.Filter,
) !void {
    for (filters) |filter| {
        var filter_arg = std.ArrayListUnmanaged(u8){};
        try filter_arg.appendSlice(arena, "--file-filter=");
        try filter_arg.appendSlice(arena, filter.name);
        try filter_arg.appendSlice(arena, " " ++ .{ZENITY_SEPARATOR});
        if (filter.extensions) |extensions| {
            for (extensions) |extension| {
                try filter_arg.appendSlice(arena, " *");
                try filter_arg.appendSlice(arena, extension);
            }
        } else {
            try filter_arg.appendSlice(arena, " *");
        }
        try args.append(arena, filter_arg.items);
    }
}

const std = @import("std");
const Thread = std.Thread;
const Allocator = std.mem.Allocator;

const zenity = @import("zenity.zig");

test {
    _ = zenity;
}

pub const Filter = struct {
    /// will show in the filter selection list on linux and windows
    name: []const u8,
    /// list of file extensions eg ".txt"
    /// null corresponds to a filter that allows every files
    extensions: ?[]const []const u8,
};

pub const SaveDialogueConfig = struct {
    placeholder_name: []const u8 = "",
    type: enum {
        directory,
        file,
    } = .file,
    filters: []const Filter = &.{},
};

pub const FileDialogueConfig = struct {
    type: enum {
        directory,
        file,
    } = .file,
    filters: []const Filter = &.{},
};

pub const DialogueError = error{
    OpeningFileDialogueFailed,
} || Allocator.Error;

pub const saveDialogue: @TypeOf(zenity.saveDialogue) = zenity.saveDialogue;

const fileDialogue: @TypeOf(zenity.fileDialogue) = zenity.fileDialogue;

pub fn fileDialogueSingle(alloc: Allocator, config: SaveDialogueConfig) DialogueError!?[]u8 {
    return fileDialogue(false, alloc, config);
}

pub fn fileDialogueMultiple(alloc: Allocator, config: SaveDialogueConfig) DialogueError![][]u8 {
    return fileDialogue(true, alloc, config);
}

test saveDialogue {
    const alloc = std.testing.allocator;
    const path = try saveDialogue(
        alloc,
        .{
            .placeholder_name = "test",
            .type = .file,
            .filters = &.{ .{
                .name = "all",
                .extensions = &.{"*"},
            }, .{
                .name = "test",
                .extensions = &.{".txt"},
            } },
        },
    );
    defer if (path) |path_| alloc.free(path_);
    std.debug.print("single path: {s}\n", .{path orelse "no file selected"});
}

test fileDialogueSingle {
    const alloc = std.testing.allocator;
    const path = try fileDialogueSingle(
        alloc,
        .{
            .type = .file,
            .filters = &.{ .{
                .name = "all",
                .extensions = &.{"*"},
            }, .{
                .name = "test",
                .extensions = &.{".txt"},
            } },
        },
    );
    defer if (path) |path_| alloc.free(path_);
    std.debug.print("single path: {s}\n", .{path orelse "no file selected"});
}

test fileDialogueMultiple {
    const alloc = std.testing.allocator;
    const paths = try fileDialogueMultiple(
        alloc,
        .{
            .type = .file,
            .filters = &.{ .{
                .name = "all",
                .extensions = &.{"*"},
            }, .{
                .name = "test",
                .extensions = &.{".txt"},
            } },
        },
    );
    defer alloc.free(paths);
    defer for (paths) |path| {
        alloc.free(path);
    };
    std.debug.print("multiple paths: \n", .{});
    for (paths) |path| {
        std.debug.print("{s}\n", .{path});
    }
}

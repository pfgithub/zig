//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.c_allocator);
    defer std.process.argsFree(std.heap.c_allocator, args);
    const arg: []const u8 = if (args.len < 2) "" else args[1];
    if (std.mem.eql(u8, arg, "ok")) {
        try demoOk();
    } else if (std.mem.eql(u8, arg, "read-after-free")) {
        try demoReadAfterFree();
    } else if (std.mem.eql(u8, arg, "write-after-free")) {
        try demoWriteAfterFree();
    } else if (std.mem.eql(u8, arg, "read-out-of-bounds")) {
        try demoReadOutOfBounds();
    } else if (std.mem.eql(u8, arg, "write-out-of-bounds")) {
        try demoWriteOutOfBounds();
    } else if (std.mem.eql(u8, arg, "read-stack-after-return")) {
        std.log.info("note: requires execution with `ASAN_OPTIONS=detect_stack_use_after_return=1`", .{});
        try demoReadStackAfterReturn();
    } else if (std.mem.eql(u8, arg, "write-stack-after-return")) {
        std.log.info("note: requires execution with `ASAN_OPTIONS=detect_stack_use_after_return=1`", .{});
        try demoWriteStackAfterReturn();
    } else if (std.mem.eql(u8, arg, "gpa")) {
        try demoGpa();
    } else {
        std.log.info(
            \\Unknown argument: {s}
            \\
            \\Available arguments:
            \\  ok
            \\  use-after-free
            \\  read-after-free
            \\  write-after-free
            \\  read-out-of-bounds
            \\  write-out-of-bounds
            \\  read-stack-after-return
            \\  write-stack-after-return
            \\  gpa
        , .{arg});
    }
}

fn demoOk() !void {
    const gpa = std.heap.c_allocator;
    const v_nonvolatile: *i32 = try gpa.create(i32);
    const v: *volatile i32 = v_nonvolatile;
    v.* = 5;
    gpa.destroy(v_nonvolatile);
}

fn demoReadAfterFree() !void {
    const gpa = std.heap.c_allocator;
    const v_nonvolatile: *i32 = try gpa.create(i32);
    const v: *volatile i32 = v_nonvolatile;
    v.* = 5;
    gpa.destroy(v_nonvolatile);
    _ = v.*;
}

fn demoWriteAfterFree() !void {
    const gpa = std.heap.c_allocator;
    const v_nonvolatile: *i32 = try gpa.create(i32);
    const v: *volatile i32 = v_nonvolatile;
    v.* = 5;
    gpa.destroy(v_nonvolatile);
    v.* = 6;
}

fn demoReadOutOfBounds() !void {
    const gpa = std.heap.c_allocator;
    const arr_nonvolatile: []i32 = try gpa.alloc(i32, 1);
    const arr: []volatile i32 = arr_nonvolatile;
    defer gpa.free(arr_nonvolatile);

    _ = arr.ptr[2];
}

fn demoWriteOutOfBounds() !void {
    const gpa = std.heap.c_allocator;
    const arr_nonvolatile: []i32 = try gpa.alloc(i32, 1);
    const arr: []volatile i32 = arr_nonvolatile;
    defer gpa.free(arr_nonvolatile);

    arr.ptr[2] = 42;
}

fn getStackPointer() *volatile i32 {
    var x: i32 = 42;
    return &x;
}

fn demoReadStackAfterReturn() !void {
    const ptr = getStackPointer();
    _ = ptr.*;
}

fn demoWriteStackAfterReturn() !void {
    const ptr = getStackPointer();
    ptr.* = 100;
}

fn demoGpa() !void {
    // demo showing gpa does not catch the out of bounds write
    var gpa_backing = std.heap.GeneralPurposeAllocator(.{}).init;
    const gpa = gpa_backing.allocator();
    const v = try gpa.alloc(i32, 1);
    const arr: []volatile i32 = v;
    arr.ptr[2] = 5;
    gpa.free(v);
}

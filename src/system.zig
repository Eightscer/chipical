const Self = @This();
const std = @import("std");
const state = @import("./state.zig");
const bios = @import("./bios.zig");
const print = std.debug.print;

const font_loc = [16]u12{
	0x1DC, 0x1B7, 0x1C7, 0x1CB,
	0x1C2, 0x1CF, 0x1D3, 0x1D7,
	0x1E0, 0x1E2, 0x1E6, 0x1EB,
	0x1F4, 0x1EF, 0x1F9, 0x1FB
};

s: state = .{},
prng: std.rand.DefaultPrng = undefined,

last_key_pressed: u4 = undefined,
key_pressed: bool = false,
key_depressed: bool = false,
screen_update: bool = false,

pub fn init_prng (c8: *Self) !void {
	c8.prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
	});
} 

pub fn press_key (c8: *Self, key: u4) void {
	if(!c8.s.key[key]){
		c8.last_key_pressed = key;
		c8.key_pressed = true;
	}
	c8.s.key[key] = true;
}

pub fn release_key (c8: *Self, key: u4) void {
	c8.s.key[key] = false;
	//c8.last_key_pressed = undefined;
}

pub fn tick (c8: *Self) void {
	if(c8.s.delay > 0) c8.s.delay -= 1;
	if(c8.s.sound > 0) c8.s.sound -= 1;
}

pub fn exec(c8: *Self) void {
	switch (c8.s.o()) {
		0x0 => switch (c8.s.k()) {
			0xE0 => {c8.s.c00E0(); c8.screen_update = true;},
			0xEE => c8.s.c00EE(),
			else => {}, //print("unknown opcode 0x{x:0>4}, skill issue\n", .{c8.s.op})
		},
		0x1 => c8.s.c1NNN(),
		0x2 => c8.s.c2NNN(),
		0x3 => c8.s.c3XKK(),
		0x4 => c8.s.c4XKK(),
		0x5 => c8.s.c5XY0(),
		0x6 => c8.s.c6XKK(),
		0x7 => c8.s.c7XKK(),
		0x8 => switch (c8.s.k() % 0x10) {
			0x0 => c8.s.c8XY0(),
			0x1 => c8.s.c8XY1(),
			0x2 => c8.s.c8XY2(),
			0x3 => c8.s.c8XY3(),
			0x4 => c8.s.c8XY4(),
			0x5 => c8.s.c8XY5(),
			0x6 => c8.s.c8XY6(),
			0x7 => c8.s.c8XY7(),
			0xE => c8.s.c8XYE(),
			else => print("unknown opcode 0x{x:0>4}, skill issue\n", .{c8.s.op})
		},
		0x9 => c8.s.c9XY0(),
		0xA => c8.s.cANNN(),
		0xB => c8.s.cBNNN(),
		0xC => c8.s.cCXKK(c8.prng.random().int(u8)),
		0xD => {c8.s.cDXYN(); c8.screen_update = true;},
		0xE => switch (c8.s.k()) {
			0x9E => c8.s.cEX9E(),
			0xA1 => c8.s.cEXA1(),
			else => print("unknown opcode 0x{x:0>4}, skill issue\n", .{c8.s.op})
		},
		0xF => switch (c8.s.k()) {
			0x07 => c8.s.cFX07(),
			0x0A => c8.s.cFX0A(&c8.key_pressed, c8.last_key_pressed),
			0x15 => c8.s.cFX15(),
			0x18 => c8.s.cFX18(),
			0x1E => c8.s.cFX1E(),
			0x29 => c8.s.cFX29(font_loc),
			0x33 => c8.s.cFX33(),
			0x55 => c8.s.cFX55(),
			0x65 => c8.s.cFX65(),
			else => print("unknown opcode 0x{x:0>4}, skill issue\n", .{c8.s.op})
		},
	}
}

pub fn draw_screen(c: *Self) void {
	for (0..31) |i| {
		print("|", .{});
		for(0..63) |j| {
			print("{c}", .{c.s.vram[(i*64)+j]});
		}
		print("|\n", .{});
	}
}

pub fn fetch_instr(self: *Self) void {
	self.s.op = (@as(u16, self.s.mem[self.s.pc]) << 8) | (self.s.mem[self.s.pc + 1]);
	self.s.pc += 2;
}

pub fn load_rom_file(self: *Self, path: []const u8) !void {
	@memset(&self.s.mem, 0);
	@memcpy(self.s.mem[0..0x200], &bios.BIOS);
	const f = std.fs.cwd().openFile(path,
	.{ .mode = .read_only }) catch {
		print("File not found: {s}\n", .{path});
		print("Falling back to BIOS...\n", .{});
		self.s.pc = 0x000;
		return error.FileNotFound;
	};
	defer f.close();
	var buf: [0xE00]u8 = undefined;
	const bytes_read = f.readAll(&buf) catch unreachable;
	@memcpy(self.s.mem[0x200..], &buf);
	print("{} bytes read\n", .{bytes_read});
	//for (&self.mem) |b| {print("{x:4}", .{b});}
}

pub fn print_state(c8: *Self) void {
	print("[PC: {x:0>4}] [SP: {x:0>4}] [I:  {x:0>4}] [OP: {x:0>4}]\n",
		.{c8.s.pc, c8.s.sp, c8.s.i, c8.s.op});
	print("V: ", .{});
	for (c8.s.v) |v| print("{x:0>2} ", .{v});
	print("\n\n", .{});
}

test "bestcoder" {
	var c8: @This() = .{.s = .{}};
	_ = try c8.load_rom_file("corax89.ch8");
	var i: u16 = 0;
	c8.s.c00E0();
	c8.draw_screen();
	c8.fetch_instr();
	c8.print_state();
	//for (c8.s.mem) |b| {print("{x:4}", .{b});}
	print("\n", .{});
	c8.exec();
	while (i < 300) : (i += 1) {
		c8.fetch_instr();
		c8.exec();
	}
	print("\n", .{});
	c8.draw_screen();
	print("\n", .{});
	//c8.print_state();
}
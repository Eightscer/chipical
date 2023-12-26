const std = @import("std");
const print = std.debug.print;

const Chip8State = struct {
	const Self = @This();
	
	v:		[16]u8 = undefined,
	sp:		u8 = 0,
	pc:		u16 = 0x200,
	i:		u16 = 0x000,
	delay:	u8 = 0,
	sound:	u8 = 0,
	key:	[16]bool = undefined,
	vram:	[64*32]u8 = undefined,
	mem:	[0x1000]u8 = undefined,
	stk:	[16]u16 = undefined,

	op:		u16 = 0x0000,

	fn o(self: *Self) u4	{return @intCast(self.op >> 12);}
	fn n(self: *Self) u12	{return @intCast(self.op & 0xFFF);}
	fn x(self: *Self) u4	{return @intCast((self.op >> 8) & 0xF);}
	fn y(self: *Self) u4	{return @intCast((self.op >> 4) & 0xF);}
	fn k(self: *Self) u8	{return @intCast(self.op & 0xFF);}

	pub fn c00E0(s: *Self) void	{@memset(&s.vram, ' ');}
	pub fn c00EE(s: *Self) void {s.sp -%= 1; s.pc = s.stk[s.sp];}
	pub fn c1NNN(s: *Self) void	{s.pc = s.n();}
	pub fn c2NNN(s: *Self) void	{s.stk[s.sp] = s.pc; s.pc = s.n(); s.sp +%= 1;}
	pub fn c3XKK(s: *Self) void {if(s.v[s.x()] == s.k()) s.pc += 2;}
	pub fn c4XKK(s: *Self) void {if(s.v[s.x()] != s.k()) s.pc += 2;}
	pub fn c5XY0(s: *Self) void {if(s.v[s.x()] == s.v[s.y()]) s.pc += 2;}
	pub fn c6XKK(s: *Self) void {s.v[s.x()] = s.k();}
	pub fn c7XKK(s: *Self) void {s.v[s.x()] +%= s.k();}
	pub fn c8XY0(s: *Self) void {s.v[s.x()] = s.v[s.y()];}
	pub fn c8XY1(s: *Self) void {s.v[s.x()] |= s.v[s.y()];}
	pub fn c8XY2(s: *Self) void {s.v[s.x()] &= s.v[s.y()];}
	pub fn c8XY3(s: *Self) void {s.v[s.x()] ^= s.v[s.y()];}
	pub fn c8XY4(s: *Self) void {
		const ov = @addWithOverflow(s.v[s.x()], s.v[s.y()]);
    	s.v[0xF] = if (ov[1] != 0) 1 else 0;
    	s.v[s.x()] = ov[0];
	}
	pub fn c8XY5(s: *Self) void {
		s.v[0xF] = if(s.v[s.x()] > s.v[s.y()]) 1 else 0;
		s.v[s.x()] -%= s.v[s.y()];
	}
	pub fn c8XY6(s: *Self) void {
		s.v[0xF] = s.v[s.x()] & 0x1;
		s.v[s.x()] >>= 1;
	}
	pub fn c8XY7(s: *Self) void {
		s.v[0xF] = if(s.v[s.y()] > s.v[s.x()]) 1 else 0;
		s.v[s.x()] = s.v[s.y()] -% s.v[s.x()];
	}
	pub fn c8XYE(s: *Self) void {
		const ov = @shlWithOverflow(s.v[s.x()], 1);
		s.v[s.x()] = ov[0]; s.v[0xF] = ov[1];
	}
	pub fn c9XY0(s: *Self) void {if(s.v[s.x()] != s.v[s.y()]) s.pc += 2;}
	pub fn cANNN(s: *Self) void {s.i = s.n();}
	pub fn cBNNN(s: *Self) void {s.pc = s.n() +% s.v[0x0];}
	pub fn cCXKK(s: *Self) void {_ = s;} //TODO: s.v[s.x()] = rng % s.k();
	
	pub fn cDXYN(s: *Self) void {
		s.v[0xF] = 0;
		for (0..(s.n()%0x10)) |r| {
			const f: u8 = s.mem[s.i +% r];
			for(0..7) |c| {
				const p: bool = (f & (@as(u8, 0x80) >> @as(u3, @intCast(c)))) != 0;
				const loc = (((s.v[s.y()]+r)%32)*64) + ((s.v[s.x()]+c)%64);
				if(p){
					if(s.vram[loc] == '#'){
						s.v[0xF] = 1; s.vram[loc] = ' ';
					} else {s.vram[loc] = '#';}
				}
			}
		}
	}

	pub fn cEX9E(s: *Self) void {if(s.key[s.x()] == true) s.pc += 2;}
	pub fn cEXA1(s: *Self) void {if(s.key[s.x()] != true) s.pc += 2;}
	pub fn cFX07(s: *Self) void {s.v[s.x()] = s.delay;}
	pub fn cFX0A(s: *Self) void { _ = s;
		//TODO lmfao
		// "Wait for a key press, store the value of the key in Vx.
		// All execution stops until a key is pressed, then the value 
		// of that key is stored in Vx."
	}
	pub fn cFX15(s: *Self) void {s.delay = s.v[s.x()];}
	pub fn cFX18(s: *Self) void {s.sound = s.v[s.x()];}
	pub fn cFX1E(s: *Self) void {s.i +%= s.v[s.x()];}
	pub fn cFX29(s: *Self) void {s.i = (s.v[s.x()] * 5) + 0;}
	pub fn cFX33(s: *Self) void {
		s.mem[s.i]		= s.v[s.x()] / 100;
		s.mem[s.i +% 1]	= (s.v[s.x()] % 100) / 10;
		s.mem[s.i +% 2]	= s.v[s.x()] % 10;
	}
	pub fn cFX55(s: *Self) void {
		var i: u8 = 0;
		while (i <= s.x()) : (i += 1) s.mem[s.i +% i] = s.v[i];
	}
	pub fn cFX65(s: *Self) void {
		var i: u8 = 0;
		while (i <= s.x()) : (i += 1) s.v[i] = s.mem[s.i +% i];
	}

	pub fn t(self: *Self) void {self.op = self.o();}
};

const Chip8System = struct {
	const Self = @This();

	const font = [_]u8{
		0xF0, 0x90, 0x90, 0x90, 0xF0,
		0x20, 0x60, 0x20, 0x20, 0x70,
		0xF0, 0x10, 0xF0, 0x80, 0xF0,
		0xF0, 0x10, 0xF0, 0x10, 0xF0,
		0x90, 0x90, 0xF0, 0x10, 0x10,
		0xF0, 0x80, 0xF0, 0x10, 0xF0,
		0xF0, 0x80, 0xF0, 0x90, 0xF0,
		0xF0, 0x10, 0x20, 0x40, 0x40,
		0xF0, 0x90, 0xF0, 0x90, 0xF0,
		0xF0, 0x90, 0xF0, 0x10, 0xF0,
		0xF0, 0x90, 0xF0, 0x90, 0x90,
		0xE0, 0x90, 0xE0, 0x90, 0xE0,
		0xF0, 0x80, 0x80, 0x80, 0xF0,
		0xE0, 0x90, 0x90, 0x90, 0xE0,
		0xF0, 0x80, 0xF0, 0x80, 0xF0,
		0xF0, 0x80, 0xF0, 0x80, 0x80
	};

	s: Chip8State,
	
	pub fn thing(c8: *Self) void {
		switch (c8.s.o()) {
			0x0 => switch (c8.s.k()) {
				0xE0 => c8.s.c00E0(),
				0xEE => c8.s.c00EE(),
				else => print("unknown opcode 0x{x:4}, skill issue\n", .{c8.s.op})
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
				else => print("unknown opcode 0x{x:4}, skill issue\n", .{c8.s.op})
			},
			0x9 => c8.s.c9XY0(),
			0xA => c8.s.cANNN(),
			0xB => c8.s.cBNNN(),
			0xC => c8.s.cCXKK(),
			0xD => {
				c8.s.cDXYN(); //c8.draw_screen();
			},
			0xE => switch (c8.s.k()) {
				0x9E => c8.s.cEX9E(),
				0xA1 => c8.s.cEXA1(),
				else => print("unknown opcode 0x{x:4}, skill issue\n", .{c8.s.op})
			},
			0xF => switch (c8.s.k()) {
				0x07 => c8.s.cFX07(),
				0x0A => c8.s.cFX0A(),
				0x15 => c8.s.cFX15(),
				0x18 => c8.s.cFX18(),
				0x1E => c8.s.cFX1E(),
				0x29 => c8.s.cFX29(),
				0x33 => c8.s.cFX33(),
				0x55 => c8.s.cFX55(),
				0x65 => c8.s.cFX65(),
				else => print("unknown opcode 0x{x:4}, skill issue\n", .{c8.s.op})
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
		const f = std.fs.cwd().openFile(path,
		.{ .mode = .read_only }) catch {
			print("File not found: {s}\n", .{path});
			return;
		};
		defer f.close();
		var buf: [0xE00]u8 = undefined;
		const bytes_read = f.readAll(&buf) catch unreachable;
		@memset(&self.s.mem, 0);
		@memcpy(self.s.mem[0..80], &font);
		@memcpy(self.s.mem[0x200..], &buf);
		print("{} bytes read\n", .{bytes_read});
		//for (&self.mem) |b| {print("{x:4}", .{b});}
	}

	pub fn print_state(c8: *Self) void {
		print("[PC: {x:4}] [SP: {x:4}] [I:  {x:4}] [OP: {x:4}]\n",
			.{c8.s.pc, c8.s.sp, c8.s.i, c8.s.op});
		print("V: ", .{});
		for (c8.s.v) |v| print("{x:2} ", .{v});
		print("\n\n", .{});
	}
};

test "o" {
	var s: Chip8State = .{};
	s.op = 0x1234;
	print("\n{x:4}\n", .{s.op});
	s.t();
	print("\n{x:4}\n", .{s.op});
}

test "op" {
	const ops = [_]u16{0x1234, 0x3456, 0x00E0, 0xFFFF, 0x1111};
	var c8: Chip8System = .{.s = .{}};
	print("\n", .{});
	for (ops) |o| {
		//print("op: {x:4}\n", .{c8.s.op});
		c8.s.op = o;
		c8.thing();
		c8.print_state();
	}
}

test "add" {
	var st: Chip8State = .{};
	st.v[1] = 0x34;
	st.v[2] = 0xDD;
	st.op = 0x8124;
	st.c8XY4();
	print("\n{} {}\n", .{st.v[1], st.v[0xF]});
}

test "bestcoder" {
	var c8: Chip8System = .{.s = .{}};
	_ = try c8.load_rom_file("corax89.ch8");
	var i: u16 = 0;
	c8.s.c00E0();
	c8.draw_screen();
	c8.fetch_instr();
	c8.print_state();
	//for (c8.s.mem) |b| {print("{x:4}", .{b});}
	print("\n", .{});
	c8.thing();
	while (i < 300) : (i += 1) {
		c8.fetch_instr();
		c8.thing();
	}
	print("\n", .{});
	c8.draw_screen();
	print("\n", .{});
	//c8.print_state();
}

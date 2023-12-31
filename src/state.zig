const Self = @This();

v:		[16]u8 = .{0x00} ** 16,
sp:		u8 = 0,
pc:		u16 = 0x200,
i:		u16 = 0x000,
delay:	u8 = 0,
sound:	u8 = 0,
key:	[16]bool = .{false} ** 16,
vram:	[64*32]u8 = .{' '} ** (64*32),
vmem:	[64*32]bool = .{false} ** (64*32),
mem:	[0x1000]u8 = undefined,
stk:	[16]u16 = .{0x0000} ** 16,

op:		u16 = 0x0000,

pub fn o(self: *Self) u4	{return @intCast(self.op >> 12);}
pub fn n(self: *Self) u12	{return @intCast(self.op & 0xFFF);}
pub fn x(self: *Self) u4	{return @intCast((self.op >> 8) & 0xF);}
pub fn y(self: *Self) u4	{return @intCast((self.op >> 4) & 0xF);}
pub fn k(self: *Self) u8	{return @intCast(self.op & 0xFF);}

pub fn c00E0(s: *Self) void	{
	@memset(&s.vram, ' ');
	s.vmem = .{false} ** (64*32);
}
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
pub fn cCXKK(s: *Self, r: u8) void {s.v[s.x()] = r % s.k();} // PRNG value must be passed in by system

pub fn cDXYN(s: *Self) void {
	s.v[0xF] = 0;
	for (0..(s.n()%0x10)) |r| {
		const f: u8 = s.mem[s.i +% r];
		for(0..8) |c| {
			const p: bool = (f & (@as(u8, 0x80) >> @as(u3, @intCast(c)))) != 0;
			const loc = (((s.v[s.y()]+r)%32)*64) + ((s.v[s.x()]+c)%64);
			if(p){
				if(s.vmem[loc]){
					s.v[0xF] = 1;
					s.vmem[loc] = false;
					s.vram[loc] = ' ';
				} else {s.vram[loc] = '#'; s.vmem[loc] = true;}
			}
		}
	}
}

pub fn cEX9E(s: *Self) void {if(s.key[s.v[s.x()]] == true) s.pc += 2;}
pub fn cEXA1(s: *Self) void {if(s.key[s.v[s.x()]] != true) s.pc += 2;}
pub fn cFX07(s: *Self) void {s.v[s.x()] = s.delay;}
pub fn cFX0A(s: *Self, key_pressed: *bool, key_id: u4) void {
	if (!key_pressed.*) {s.pc -%= 2;} else {
		s.v[s.x()] = key_id;
		key_pressed.* = false;
	}
}
pub fn cFX15(s: *Self) void {s.delay = s.v[s.x()];}
pub fn cFX18(s: *Self) void {s.sound = s.v[s.x()];}
pub fn cFX1E(s: *Self) void {s.i +%= s.v[s.x()];}
//pub fn cFX29(s: *Self) void {s.i = (s.v[s.x()] * 5) + 0;}
pub fn cFX29(s: *Self, loc: [16]u12) void {s.i = loc[s.v[s.x()] & 0xF];}
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

test "add" {
	const print = @import("std").debug.print;
	var st: Self = .{};
	st.v[1] = 0x34;
	st.v[2] = 0xDD;
	st.op = 0x8124;
	st.c8XY4();
	print("\n{} {}\n", .{st.v[1], st.v[0xF]});
}
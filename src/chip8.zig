const std = @import("std");

pub fn Chip8(fba: std.heap.FixedBufferAllocator) type {
	return struct {
		const Self = @This();
		prng: std.rand.Random,
		alloc: std.mem.Allocator,

		pub const s = struct {
			pc: u12 = 0x0200,
			i: u12 = 0x200,
			v: u8[16],
			k: bool[16],
			stack: u16[16],
			sp: u4 = 0x0,
			delay: u8 = 0x00,
			sound: u8 = 0x00,
			ram: *u8,
			vram: bool[64 * 32],
			o: u16 = 0x0000,
			
			//pub fn x(s: @This()) u4		{ return (s.o >> 8) & 0xF;	}
			//pub fn y(s: @This()) u4		{ return (s.o >> 4) & 0xF;	}
			//pub fn b(s: @This()) u8		{ return s.o & 0xFF;		}
			//pub fn n(s: @This()) u12	{ return s.o & 0xFFF;		}

			const x: u4 = (@This().o >> 8) & 0xF;
			const y: u4 = (@This().o >> 4) & 0xF;
			const b: u8 = @This().o & 0xFF;
			const n: u12 = @This().o & 0xFFF; 
		};

		pub fn init() Chip8 {
			var x = std.rand.DefaultPrng.init(blk: {
					var seed: u64 = undefined;
					try std.os.getrandom(std.mem.asBytes(&seed));
					break: blk seed;
				});

			var c8 = Chip8(fba){.prng = x, .alloc = fba.allocator()};

			// state initialization logic

			return c8;
		}

		fn RET	(c: *Self.s) void {	c.pc -= 1; c.pc = c.stack[c.sp];		}
		fn JP	(c: *Self.s) void {	c.pc = c.n;								}
		fn CALL	(c: *Self.s) void {	c.stack[c.sp] = c.pc; c.sp += 1; JP(c);	}
		fn SEB	(c: *Self.s) void {	if(c.v[c.x] == c.b) c.pc += 2;			}
		fn SNEB	(c: *Self.s) void {	if(c.v[c.x] != c.b) c.pc += 2;			}
		fn SEV	(c: *Self.s) void {	if(c.v[c.x] == c.v[c.y]) c.pc += 2;		}
		fn LDB	(c: *Self.s) void {	c.v[c.x] = c.b;							}
		fn ADD	(c: *Self.s) void {	c.v[c.x] += c.b;						}
		fn SNEV	(c: *Self.s) void {	if(c.v[c.x] != c.v[c.y]) c.pc += 2;		}
		fn LDI	(c: *Self.s) void {	c.i = c.n;								}
		fn JPV	(c: *Self.s) void {	c.pc = (c.o & 0xFFF) + c.v[0];			}
		fn RND	(c: *Self.s, rng: *Self.prng) void {c.v[c.x] = rng.int(u8);	}

		fn DRW	(c: *Self.s) void {
			c.v[0xF] = 0; // TODO
		}

		fn LDXY	(c: *Self.s) void {	c.v[c.x] = c.v[c.y];					}
		fn ORV	(c: *Self.s) void {	c.v[c.x] = c.v[c.x] | c.v[c.y];			}
		fn AND	(c: *Self.s) void {	c.v[c.x] = c.v[c.x] & c.v[c.y];			}
		fn XOR	(c: *Self.s) void {	c.v[c.x] = c.v[c.x] ^ c.v[c.y];			}
		//fn _84	(c: *Self.s) void {	c.v[c.x] = c.v[c.y];					}
		//fn _85	(c: *Self.s) void {	c.v[c.x] = c.v[c.y];					}
		//fn _86	(c: *Self.s) void {	c.v[c.x] = c.v[c.y];					}
		//fn _87	(c: *Self.s) void {	c.v[c.x] = c.v[c.y];					}
		//fn _8E	(c: *Self.s) void {	c.v[c.x] = c.v[c.y];					}

		fn SKP	(c: *Self.s) void {	if(c.k[c.x & 0xF] == true)	c.pc += 2;	}
		fn SKNP	(c: *Self.s) void {	if(c.k[c.x & 0xF] == false)	c.pc += 2;	}

		fn STDT (c: *Self.s) void {	c.v[c.x] = c.delay;						}
		//0a
		fn LDDT (c: *Self.s) void {	c.delay = c.v[c.x];						}
		fn LDSN (c: *Self.s) void {	c.sound = c.v[c.x];						}
		fn ADDI (c: *Self.s) void {	c.i += c.v[c.x];						}
		//29
		//33
		//55
		//65
	};
}
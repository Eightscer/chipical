// 8SCR_BIOS.ch8
// Chip8 program that resides in chipical's reserved interpreter memory.
// Allows you to write anywhere to memory and jump to it, meaning you could
// write an entire program from scratch if you wanted to. If no ROM is present
// (via FileNotFound) or if the -b (--bios) option is used, chipical will run
// at 0x000, the start of this program.

pub const BIOS = [0x200]u8{
	// init v2 = 1, v3 = f
	0x62, 0x01, 0x63, 0x0F, 0x11, 0x00, 0x00, 0x10,

	// workspace: 0x008
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

	// refresh screen: 0x018
	0x00, 0xE0, 0x68, 0x15, 0x69, 0x01, 0x6A, 0x08,
	0x20, 0x64, 0xA1, 0xBB, 0x20, 0x66, 0x6A, 0x0C,
	0x20, 0x64, 0xA1, 0xBF, 0x20, 0x66, 0x00, 0xEE,

	// print current: 0x030
	0x68, 0x01, 0x69, 0x14, 0x20, 0xDC, 0x20, 0x4C,
	0xA1, 0xB2, 0x20, 0x66, 0x20, 0xF0, 0x21, 0x90,
	0x20, 0x4C, 0x00, 0xEE,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

	// print v4567: 0x04C
	0x8A, 0x40, 0x20, 0x64, 0x8A, 0x50, 0x20, 0x64,
	0x8A, 0x60, 0x20, 0x64, 0x8A, 0x70, 0x20, 0x64,
	0x00, 0xEE,
	0x8D, 0x00, 0x8E, 0x10,	0x10, 0xDC,

	// load num, print, move x by 5, ret: 0x064
	0xFA, 0x29, 0xD8, 0x95, 0x78, 0x05, 0x00, 0xEE,

	// get key and print, print digit: 0x06C
	0xA1, 0xAA, 0xD8, 0x95, 0xFA, 0x0A, 0xA1, 0xAA,
	0xD8, 0x95, 0xFA, 0x29, 0x20, 0x66, 0x00, 0xEE,

	// shl va 4: 0x07C
	0x8A, 0x1E, 0x8A, 0x1E, 0x8A, 0x1E, 0x8A, 0x1E,
	0x00, 0xEE,
	// shr v4 4: 0x086
	0x84, 0x16, 0x84, 0x16, 0x84, 0x16, 0x84, 0x16,
	0x00, 0xEE,
	
	// type instr, type2: 0x090
	0x20, 0x6C, 0x84, 0xA0, 0x20, 0x7C, 0x80, 0xA0,
	0x20, 0x6C, 0x85, 0xA0, 0x80, 0xA1, 0x20, 0x6C,
	0x86, 0xA0, 0x20, 0x7C, 0x81, 0xA0, 0x20, 0x6C,
	0x87, 0xA0, 0x81, 0xA1, 0x00, 0xEE, 0x00, 0x00,
	
	// confirm command: 0x0B0
	0x21, 0xA4, 0xFB, 0x0A, 0x00, 0xEE, 0x00, 0x00,
	
	// store instr: 0x0B8
	0xA0, 0xC2, 0xF1, 0x55, 0x00, 0xEE, 0x00, 0x00,
	
	// custom instr: 0x0C0
	0x00, 0xE0, 0x00, 0x00, 0x00, 0xEE, 0x00, 0x00,
	

	// v4567_to_de: 0x0C8
	0x8A, 0x40, 0x20, 0x7C, 0x8D, 0xA0, 0x8D, 0x51,
	0x8A, 0x60, 0x20, 0x7C, 0x8E, 0xA0, 0x8E, 0x71,
	0x00, 0xEE, 0x00, 0x00, 
	
	// vde_to_4567: 0x0DC
	0x87, 0xE0, 0x87, 0x32, 0x84, 0xE0, 0x20, 0x86,
	0x86, 0x40, 0x85, 0xD0, 0x85, 0x32, 0x84, 0xD0,
	0x20, 0x86, 0x00, 0xEE,

	// load_v01_from_vde: 0x0F0
	0x8D, 0x32, 0x60, 0xA0, 0x80, 0xD1, 0x81, 0xE0,
	0x20, 0xB8, 0x20, 0xC2, 0xF1, 0x65, 0x00, 0xEE,

	// main: 0x100
	0x20, 0x18, 0x8D, 0x32, 0x20, 0x30, 0x68, 0x01, 
	0x69, 0x1A, 0x21, 0xA4, 0xFA, 0x0A, 0x21, 0xA4,
	0x4A, 0x00, 0x11, 0x7A,
	0x4A, 0x01, 0x11, 0x30,
	0x4A, 0x02, 0x11, 0x30,
	0x4A, 0x03, 0x11, 0x40,
	0x4A, 0x04, 0x11, 0x40,
	0x4A, 0x05, 0x11, 0x68,
	0x4A, 0x06, 0x11, 0x60,
	0x11, 0x08,	0x00, 0x00,
	
	
	// seq1: 0x130
	0x20, 0x64, 0x20, 0x92, 0x20, 0xC8, 0x20, 0xB0,
	0x4B, 0x00, 0x11, 0x00, 0x20, 0xB8, 0x10, 0xC0,	
	
	// seq3: 0x140
	0x21, 0x8A, 0x8C, 0xA0, 0x6A, 0x0A, 0x20, 0x92,
	0x20, 0xC8, 0x21, 0x8A,	0x4C, 0x03, 0x11, 0x00,
	// seq4: 0x150
	0x20, 0xB8, 0x20, 0x90,	0x20, 0xB0, 0x4B, 0x00,
	0x11, 0x00, 0x20, 0xC2, 0xF1, 0x55, 0x11, 0x00,
	

	// seq6: 0x160
	0x6C, 0x02, 0x8E, 0xC4, 0x3F, 0x00, 0x7D, 0x01,
	// seq5: 0x168
	0x21, 0x8A, 0x20, 0xDC, 0x20, 0x50, 0x21, 0x8A,
	0x64, 0x0A, 0x20, 0xC8, 0x80, 0xD0, 0x81, 0xE0,
	0x11, 0x50,

	// seq0: 0x17A
	0x60, 0x12, 0x61, 0x00, 0x21, 0x90, 0x20, 0x4C,
	0x11, 0x34,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

	// print colon and move: 0x18A
	0xA1, 0xB2, 0x20, 0x66, 0x00, 0xEE,


	// v01 to 4567: 0x190
	0x87, 0x10, 0x87, 0x32, 0x84, 0x10, 0x20, 0x86,
	0x86, 0x40, 0x85, 0x00, 0x85, 0x32, 0x84, 0x00,
	0x20, 0x86, 0x00, 0xEE,

	// print ?: 0x1A4
	0xA1, 0xAE, 0xD8, 0x95, 0x00, 0xEE,
	
	// 0x200 - 0x56 = 0x1AA
	0xF0, 0xF0, 0xF0, 0xF0, //0xF0,	// Cursor sprite	1aa
	0xF0, 0x10, 0x70, 0x00, //0x60,	// ? sprite			1ae
	0x60, 0x60, 0x00, 0x60, 0x60,	// : sprite			1b2
	0x20, 0x60, 0x20, 0x20, //0x70,	// 1				1b7
	0x70, 0x80, 0x60, 0x10, //0xE0,	// S sprite			1bb
	0xE0, 0x90, 0xE0, //0x90, 0x90,	// R sprite			1bf
	0x90, 0x90, 0xF0, 0x10, 0x10,	// 4				1c2
	0xF0, 0x10, 0xF0, 0x80, //0xF0,	// 2				1c7
	0xF0, 0x10, 0xF0, 0x10, //0xF0,	// 3				1cb
	0xF0, 0x80, 0xF0, 0x10, //0xF0,	// 5				1cf
	0xF0, 0x80, 0xF0, 0x90, //0xF0,	// 6				1d3
	0xF0, 0x10, 0x20, 0x40, 0x40,	// 7				1d7
	0xF0, 0x90, 0x90, 0x90, //0xF0,	// 0				1dc
	0xF0, 0x90, //0xF0, 0x90, 0xF0,	// 8				1e1
	0xF0, 0x90, 0xF0, 0x10, //0xF0,	// 9				1e3
	0xF0, 0x90, 0xF0, 0x90, 0x90,	// A				1e7
	0xE0, 0x90, 0xE0, 0x90, //0xE0,	// B				1eb
	0xE0, 0x90, 0x90, 0x90, 0xE0,	// D				1ef
	0xF0, 0x80, 0x80, 0x80, 0xF0,	// C				1f4
	0xF0, 0x80, //0xF0, 0x80, 0xF0,	// E				1f9
	0xF0, 0x80, 0xF0, 0x80, 0x80	// F				1fb

};
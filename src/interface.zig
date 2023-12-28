const std = @import("std");
const sys = @import("./system.zig");
const print = std.debug.print;

const C = @cImport({
	@cInclude("SDL.h");
});

const Self = @This();

scale: c_int = 10,

fgcolor: u32 = 0x00FF7FFF,
bgcolor: u32 = 0x000000FF,

mapping: [16]C.SDL_Keycode = .{
	C.SDLK_x, C.SDLK_1, C.SDLK_2, C.SDLK_3,
	C.SDLK_q, C.SDLK_w, C.SDLK_e, C.SDLK_a,
	C.SDLK_s, C.SDLK_d, C.SDLK_z, C.SDLK_c,
	C.SDLK_4, C.SDLK_r, C.SDLK_f, C.SDLK_v
},

system: sys = .{},
video: [64*32]u32 = .{0x000000FF} ** (64*32),

window: ?*C.SDL_Window = undefined,
render: ?*C.SDL_Renderer = undefined,
texture: ?*C.SDL_Texture = undefined,

pub fn init_sdl (emu: *Self) void {
	emu.window = C.SDL_CreateWindow("corax89.ch8", C.SDL_WINDOWPOS_CENTERED, 
		C.SDL_WINDOWPOS_CENTERED, 64*emu.scale, 32*emu.scale, C.SDL_WINDOW_SHOWN);
	emu.render = C.SDL_CreateRenderer(emu.window, 0, C.SDL_RENDERER_PRESENTVSYNC);
	emu.texture = C.SDL_CreateTexture(emu.render, C.SDL_PIXELFORMAT_RGBA8888,
		C.SDL_TEXTUREACCESS_STREAMING, 64, 32);
}

pub fn deinit_sdl (emu: *Self) void {
	C.SDL_DestroyTexture(emu.texture);
	C.SDL_DestroyRenderer(emu.render);
	C.SDL_DestroyWindow(emu.window);
}

pub fn update_gfx (emu: *Self) void {
	for (0..emu.system.s.vmem.len) |p| {
		emu.video[p] = if(emu.system.s.vmem[p]) emu.fgcolor else emu.bgcolor;
	}
	_ = C.SDL_UpdateTexture(emu.texture, null, @ptrCast(&emu.video), (64 * @sizeOf(u32)));
	_ = C.SDL_RenderClear(emu.render);
	_ = C.SDL_RenderCopy(emu.render, emu.texture, null, null);
	_ = C.SDL_RenderPresent(emu.render);
}

pub fn main() !void {
	_ = C.SDL_Init(C.SDL_INIT_EVERYTHING);
	var emu: Self = .{};
	init_sdl(&emu);
	defer deinit_sdl(&emu);

	_ = try emu.system.load_rom_file("corax89.ch8");
	emu.system.s.c00E0();
	for (0..500) |_| {
		emu.system.fetch_instr();
		emu.system.exec();
	}

	loop: while (true) {
		var e: C.SDL_Event = undefined;
		while (C.SDL_PollEvent(&e) != 0) {
			switch (e.type) {
				C.SDL_QUIT => break :loop,
				else => {},
			}
		}
		if(emu.system.screen_update) {
			emu.system.screen_update = false;
			emu.update_gfx();
		}
	}
	
}
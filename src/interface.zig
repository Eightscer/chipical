const std = @import("std");
const sys = @import("./system.zig");
const clap = @import("./zig-clap/clap.zig");
const bios = @import("./bios.zig");
const print = std.debug.print;

const C = @cImport({
    @cInclude("SDL.h");
});

const Self = @This();

scale: c_int = 10,

fgcolor: u32 = 0x00FF7FFF,
bgcolor: u32 = 0x000000FF,

mapping: [16]C.SDL_Keycode = .{ C.SDLK_x, C.SDLK_1, C.SDLK_2, C.SDLK_3, C.SDLK_q, C.SDLK_w, C.SDLK_e, C.SDLK_a, C.SDLK_s, C.SDLK_d, C.SDLK_z, C.SDLK_c, C.SDLK_4, C.SDLK_r, C.SDLK_f, C.SDLK_v },

system: sys = .{},

freq_cap: u64 = 100000,

quit: bool = false,
pause: bool = false,
held: bool = false,
instant_render: bool = false,
video: [64 * 32]u32 = .{0x000000FF} ** (64 * 32),

window: ?*C.SDL_Window = undefined,
render: ?*C.SDL_Renderer = undefined,
texture: ?*C.SDL_Texture = undefined,

pub fn init_sdl(emu: *Self) void {
    emu.window = C.SDL_CreateWindow("chipical", C.SDL_WINDOWPOS_CENTERED, C.SDL_WINDOWPOS_CENTERED, 64 * emu.scale, 32 * emu.scale, C.SDL_WINDOW_SHOWN);
    emu.render = C.SDL_CreateRenderer(emu.window, 0, C.SDL_RENDERER_PRESENTVSYNC);
    emu.texture = C.SDL_CreateTexture(emu.render, C.SDL_PIXELFORMAT_RGBA8888, C.SDL_TEXTUREACCESS_STREAMING, 64, 32);
}

pub fn deinit_sdl(emu: *Self) void {
    C.SDL_DestroyTexture(emu.texture);
    C.SDL_DestroyRenderer(emu.render);
    C.SDL_DestroyWindow(emu.window);
}

pub fn update_gfx(emu: *Self) void {
    for (0..emu.system.s.vmem.len) |p| {
        emu.video[p] = if (emu.system.s.vmem[p]) emu.fgcolor else emu.bgcolor;
    }
    _ = C.SDL_UpdateTexture(emu.texture, null, @ptrCast(&emu.video), (64 * @sizeOf(u32)));
    _ = C.SDL_RenderClear(emu.render);
    _ = C.SDL_RenderCopy(emu.render, emu.texture, null, null);
    _ = C.SDL_RenderPresent(emu.render);
}

pub fn handle_input(emu: *Self) void {
    var e: C.SDL_Event = undefined;
    while (C.SDL_PollEvent(&e) != 0) {
        switch (e.type) {
            C.SDL_QUIT => {
                emu.quit = true;
            },
            C.SDL_KEYDOWN => {
                const k: C.SDL_Keycode = e.key.keysym.sym;
                for (0..16) |p| {
                    const x: u4 = @as(u4, @intCast(p));
                    if (k == emu.mapping[x]) emu.system.press_key(x);
                }
                if (k == C.SDLK_ESCAPE) {
                    emu.quit = true;
                }
                if (k == C.SDLK_p) {
                    if (!emu.held) {
                        emu.held = true;
                        emu.pause = if (emu.pause) false else true;
                    }
                }
            },
            C.SDL_KEYUP => {
                emu.held = false;
                const k: C.SDL_Keycode = e.key.keysym.sym;
                for (0..16) |p| {
                    const x: u4 = @as(u4, @intCast(p));
                    if (k == emu.mapping[x]) emu.system.release_key(x);
                }
            },
            else => {},
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h,	--help				Displays this help menu and exits.
        \\-p,	--paused			Start the interpreter in a paused state
        \\-i,	--instant			Instantly renders screen on every DRAW instruction
        \\-b,	--bios				Starts at PC = 0x000, containing a builtin-ROM
        \\-f,	--freq <FREQ>		Specifies max frequency for interpreter (default 100000)
        \\-s,	--scale <SCALE>		Scaling factor of application window (default 10)
        \\--foreground <FG>	RGBA color value for sprites
        \\--background <BG>	RGBA color value for background
        \\<FILE>...
        \\
    );

    const parsers = comptime .{
        .FREQ = clap.parsers.int(u64, 10),
        .SCALE = clap.parsers.int(c_int, 10),
        .FILE = clap.parsers.string,
        .BG = clap.parsers.int(u32, 16),
        .FG = clap.parsers.int(u32, 16),
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});

    var emu: Self = .{};

    if (res.args.freq) |f| {
        if (f > 1000000000 / 60) {
            print("Frequency cap too high, defaulting to {}\n", .{emu.freq_cap});
        } else if (f == 0) {
            print("Very funny.\n", .{});
        } else {
            emu.freq_cap = f;
        }
    }
    if (res.args.scale) |s| {
        if (s < 1 or s > 120) {
            print("Invalid scaling factor, defaulting to {} ({}x{})\n", .{ emu.scale, emu.scale * 64, emu.scale * 32 });
        } else {
            emu.scale = s;
        }
    }
    if (res.args.paused != 0) {
        emu.pause = true;
    }
    if (res.args.instant != 0) {
        emu.instant_render = true;
    }
    if (res.args.bios != 0) {
        emu.system.s.pc = 0;
    }
    if (res.args.foreground) |c| {
        emu.fgcolor = c;
    }
    if (res.args.background) |c| {
        emu.bgcolor = c;
    }
    //for (res.positionals) |pos| {_ = emu.system.load_rom_file(pos) catch {};}
    if (res.positionals.len > 0) {
        _ = emu.system.load_rom_file(res.positionals[0]) catch {};
    } else {
        print("No file specified. Booting to BIOS...\n", .{});
        @memset(&emu.system.s.mem, 0);
        @memcpy(emu.system.s.mem[0..0x200], &bios.BIOS);
        emu.system.s.pc = 0x000;
    }

    _ = try emu.system.init_prng();

    _ = C.SDL_Init(C.SDL_INIT_EVERYTHING);

    init_sdl(&emu);
    defer deinit_sdl(&emu);

    emu.system.s.c00E0();
    emu.update_gfx();

    var t: u32 = 0;
    var currt: u32 = C.SDL_GetTicks();
    const delay_dt: u32 = 16; // 1000 / 60 = ~16ms
    var acc: u32 = 0;
    const nsleep: u64 = 1000000000 / emu.freq_cap;

    while (!emu.quit) {
        const now: u32 = C.SDL_GetTicks();
        const difft: u32 = now - currt;
        currt = now;

        emu.handle_input();

        if (!emu.pause) {
            acc += difft;
            while (acc >= delay_dt) : (acc -= delay_dt) {
                if (emu.system.screen_update and !emu.instant_render) {
                    emu.system.screen_update = false;
                    emu.update_gfx();
                }
                emu.system.tick();
                t += delay_dt;
            }

            emu.system.fetch_instr();
            emu.system.exec();

            if (emu.system.screen_update and emu.instant_render) {
                emu.system.screen_update = false;
                emu.update_gfx();
            }
        }

        std.time.sleep(nsleep);
    }
}

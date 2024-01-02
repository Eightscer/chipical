# Chipical

_Output of [corax89's test ROM](https://github.com/corax89/chip8-test-rom)_

![chipical_corax89](https://github.com/Eightscer/chipical/assets/98068092/3c1ff006-aa4b-465c-9051-07552b12b597)

_Built-in ROM_

![chipical_bios](https://github.com/Eightscer/chipical/assets/98068092/53891aa7-64ef-4e60-be96-4a0599f16abe)

## Another typical Chip8 interpreter

A Chip8 interpreter I wrote in Zig to get a better handle of the Zig programming language. It's unlikely that I will update this project further aside from further exploring features of the language.

Interops with SDL2 for graphics and input handing.

### Usage

`chipical [OPTIONS] [FILE]`

```
-p,  --paused             Start the interpreter in a paused state
-i,  --instant            Instantly renders screen on every DRAW instruction
-b,  --bios               Starts at PC = 0x000, containing a builtin-ROM
-f,  --freq <FREQ>        Specifies max frequency for interpreter (default 100000)
-s,  --scale <SCALE>      Scaling factor of application window (default 10)
```

The keypad is mapped `{0, 1, ..., E, F} -> {X, 1, 2, 3, Q, W, E, A, S, D, Z, C, 4, R, F, V}`.

`P` will pause emulation, and `ESC` will quit the program.

### Built-in ROM

Chipical has a built-in ROM located within the reserved section of memory between `0x000` and `0x200`. This is a "BIOS" that allows you to write and jump to anywhere in memory. Starting chipical with the `-b` option will start emulation in this ROM, or if the program counter overflows back to `0x000`.

Here, you are prompted to press a key on the keypad to issue these following commands:
* `0`: Jump to the normal starting point (`0x200`)
* `1`: Jump to a location in memory
* `2`: Call a subroutine within a location in memory
* `3`: Probe an address to see its 16-bit value
* `4`: Specify an address and write a 16-bit value to it
* `5`: Write a 16-bit value to the address previewed on screen
* `6`: Write a 16-bit value to the next address (current + 2)

For all commands except `3`, you will be presented with a `?` prompt after typing a value. This is asking you to confirm the command you are issuing. If you made a mistake in writing, you can press `0` to cancel the command, otherwise pressing any other key will carry out the command you specified.

### TODO

- Debugging mode, stepping through program per cycle and viewing register values
- Additional command line arguments for customization (colors)
- Saving and loading configurations from a JSON file
- Sound

Credit to [Hejsil's zig-clap](https://github.com/Hejsil/zig-clap) for simple and effective command line argument parsing.

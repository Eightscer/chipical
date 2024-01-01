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

### TODO

- Debugging mode, stepping through program per cycle and viewing register values
- Additional command line arguments for customization (colors)
- Saving and loading configurations from a JSON file
- Sound

Credit to [Hejsil's zig-clap](https://github.com/Hejsil/zig-clap) for simple and effective command line argument parsing.

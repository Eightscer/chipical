# Chipical

![chipical](https://github.com/Eightscer/chipical/assets/98068092/d876693b-f820-440a-8d24-7a37d0b62dcd)

_Output of [corax89's test ROM](https://github.com/corax89/chip8-test-rom)_

### Another typical Chip8 interpreter

A Chip8 interpreter I wrote in Zig to get a better handle of the Zig programming language. It's unlikely that I will update this project further aside from further exploring features of the language.

Currently does not run ROMs in real time, nor does it have support for all instructions. Keypad handling and random-number generation is not supported yet.
Screen is printed through terminal output.

### TODO

- Command line arguments to load ROMs and run for certain number of cycles
- Emulate keypad button presses
- Implement CXKK opcode (random number generation)
- Implement FX0A opcode (wait for keypad press)
- Emulation of time to decrement the delay and sound timers

In the past I have also written a Chip8 interpreter in C that uses SDL2 for button handling, timing, and drawing the screen to a separate window. In the future I may adapt this code to this Zig-based version.

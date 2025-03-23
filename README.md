# A reversi game that fits in a boot sector (512 bytes)

**boot_reversi** is a simple reversi game that fits in a boot sector (510 bytes + 2 bytes as the boot signature).

[Play it on your browser here.](https://couyoh.github.io/boot_reversi/)

## Build

Requirement: NASM

```shell
make
```


## Run

To run with Bochs debugger:
```shell
make debug
```

## How to play

Type the coordinates of the first and second moves alternately.  
The coordinates are specified by combining the column (a–h) and the row (1–8).

The example coordinates:
- `a1`: Top-left of the board  
- `h8`: Bottom-right of the board

The initial screen:
```
abcdefgh                                                                        
........1                                                                       
........2                                                                       
........3                                                                       
...OX...4                                                                       
...XO...5                                                                       
........6                                                                       
........7                                                                       
........8                                                                       
```

On this screen:
- `O`: The first player  
- `X`: The second player

If you type `f4` on the initial screen:
```
abcdefgh                                                                        
........1                                                                       
........2                                                                       
........3                                                                       
...OOO..4                                                                       
...XO...5                                                                       
........6                                                                       
........7                                                                       
........8                                                                       
```

Then, you're the second player. If you type `f5`:
```
abcdefgh                                                                        
........1                                                                       
........2                                                                       
........3                                                                       
...OOO..4                                                                       
...XXX..5                                                                       
........6                                                                       
........7                                                                       
........8                                                                       
```

bits 16
CPU 386

%define MAX_X 8
%define MAX_Y 8
%define EMPTY '.'
%define USER1 'O'
%define USER2 'X'

%macro subneg 2
    sub %1, %2
    ; jns ($-$$)+6 ; if abs
    neg %1
%endmacro

%macro DEBUG 0
    xchg bx, bx
%endmacro

jmp init

player db 0

map_enabled db 0b00000000, ; 1
            db 0b00000000, ; 2
            db 0b00000000, ; 3
            db 0b00011000, ; 4
            db 0b00011000, ; 5
            db 0b00000000, ; 6
            db 0b00000000, ; 7
            db 0b00000000  ; 8

       ; hgfedcba
map db 0b00000000, ; 1
    db 0b00000000, ; 2
    db 0b00000000, ; 3
    db 0b00010000, ; 4
    db 0b00001000, ; 5
    db 0b00000000, ; 6
    db 0b00000000, ; 7
    db 0b00000000  ; 8

init:
    mov bx, 0x7c0
    mov ds, bx
    mov ax, 3 ; Ensure ah zero
    int 0x10

draw:
    mov cx, MAX_X ; Ensure ch zero
    .title:
        mov al, 'i'
        sub al, cl
        call putchar
        loop .title
        ; now cx is 0

    xor bx, bx
    .x:
        xor cx, cx
        call print_0d0a
        cmp bl, MAX_Y
        jge main

        .y:
            bt [bx+3], cx
            jnc .print_empty
            bt [bx+3+8], cx
            jnc .print_USER1
            mov al, USER2
            jmp .putchar

            .print_USER1:
                mov al, USER1
                jmp .putchar

            .print_empty:
                mov al, EMPTY

            .putchar:
                call putchar
                ; if decrementing (like loop inst do), it might be inverted.
                inc cl
                cmp cl, MAX_X
                jl .y

        .print_number:
            mov al, '1'
            add al, bl
            call putchar

        ; if decrementing (like loop inst do), it might be inverted.
        inc bl
        jmp .x

main:
    call wait_key ; x must be between a and h
    sub al, 'a'
    xchg cl, al
    call wait_key ; y must be between 1 and 8
    sub al, '1'
    xchg bl, al
    call print_0d0a

    call .routine
    call .routine

    ; rotate90 overwrites map_enabled and map.
    ; That's why it calls rotate90 multiple times.
    call rotate90 ; 240
    call rotate90 ; 360

    ; inverse
    mov di, 1
    push bx
    push cx
    call intercept
    call askew
    pop cx
    pop bx
    mov dx, 0x7c00+.inc_sidi ; shorter than ds:.inc_sidi
    call detection

    ; direct
    mov di, -1
    push bx
    push cx
    call .subneg
    call askew
    pop cx
    pop bx
    mov dx, 0x7c00+.inc_sidi_decdi ; shorter than ds:.inc_sidi_decdi
    call detection

    ; Toggle player if the stone has enabled.
    bt [bx+3], cx
    jnc .draw
    xor byte [2], 1

    .draw:
    jmp draw

    .inc_sidi:
        add cx, bp
        call intercept
        add bl, al
        jmp .adjust
    .inc_sidi_decdi:
        add cx, bp
        call .subneg
        sub bl, al
    .adjust:
        mov cl, al
        add cx, si
        ret
    .subneg:
        subneg bx, 7
        call intercept
        subneg bx, 7
        ret

    .normal:
        mov cx, ax
    .lea_sidi:
        lea si, [bx+3]
        lea di, [bx+3+8]
        ret

    .routine:
        mov si, [bx+3] ; movzx is 4bytes, thgough mov is 3bytes
        mov di, [bx+3+8]
        mov dx, 0x7c00+.normal ; shorter than ds:.normal
        xor bp, bp
        call detection
        call rotate90
        ret

intercept:
    sub bx, cx
    js .set_cx
    xor cx, cx
    xor si, si
    ret
    .set_cx:
        xchg bx, cx
        neg cx
        mov si, cx
        xor bx, bx
        ret

detection:
    push cx
    sub cx, bp
    mov ch, 1
    call find
    mov bh, al
    neg ch
    call find
    xor ch, ch
    xchg bh, ah
    cmp al, ah
    je .end

    .write:
        push cx
        push bx
        call dx
        call main.lea_sidi
        pop bx
        xor ch,ch
        cmp al, ah
        jg .ret
        cmp byte [2], 0
        jnz .set_player2
        .set_player1:
            btr [di], cx
            jmp .next
        .set_player2:
            bts [di], cx
        .next:
            bts [si], cx
        inc al
        pop cx
        jmp .write
    .ret:
        pop cx
    .end:
        pop cx
        ret

find:
    mov al, cl
    .loop:
        xor ah, ah
        add al, ch
        jl .restore
        cmp al, MAX_X
        jg .restore
        bt si, ax
        jnc .restore

        bt di, ax
        setc ah
        cmp ah, [2]
        jnz .loop

        xor ah, ah
        neg ch
        add al, ch
        neg ch
        ret

    .restore:
        mov al, cl
        ret

rotate90:
    mov si, 3
    call ._rotate90
    add si, 8
    call ._rotate90
    xchg cx, bx
    subneg bx, MAX_X-1
    ret

    ._rotate90:
        pusha
        xor cx, cx
        .outer_loop:
            cmp cx, MAX_X
            jz .end

            xor ax, ax
            xor bx, bx
            .inner_loop:
                cmp bx, MAX_Y
                jz .outer_next
                bt [si+bx], cx
                jnc .finally
                bts ax, bx
                .finally:
                    inc bx
                    jmp .inner_loop

            .outer_next:
                push ax
                inc cx
                jmp .outer_loop
        .end:
            xor bx, bx
            .loop:
                cmp bx, MAX_Y
                jz .ret
                pop ax
                mov [si+bx], al
                inc bx
                jmp .loop
            .ret:
                popa
                ret
askew:
    push si
    xor ax, ax
    xor si, si
    .bitmap_check:
        cmp bx, MAX_Y
        jge .end
        cmp cx, MAX_X
        jge .end
        bt [bx+3+8], cx
        jnc .enabled_check
        bts ax, si ; al = map
        .enabled_check:
            bt [bx+3], cx
            jnc .next
            xchg al, ah
            bts ax, si ; ah = map_enabled
            xchg ah, al
        .next:
            inc cx
            inc si
            add bx, di
            js .end ; cx < 0
            jmp .bitmap_check
    .end:
        movzx si, ah
        movzx di, al
        pop bp ; si
        ret

putchar:
    pusha
    mov ah, 0xe
    xor bx, bx
    int 0x10
    popa
    ret

print_0d0a:
    mov al, 0x0d
    call putchar
    mov al, 0x0a
    call putchar
    ret

wait_key:
    xor ax, ax
    int 0x16
    call putchar
    ret

times 510-($-$$) db 0
db 0x55, 0xaa

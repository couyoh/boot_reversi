bits 16
CPU 386

%define MAX_X 8
%define MAX_Y 8
%define EMPTY '.'
%define USER1 'O'
%define USER2 'X'

%macro abs 2
    sub %1, %2
    neg %1
%endmacro

%macro DEBUG 0
    xchg bx, bx
%endmacro

jmp init

player db 0

; bt inst's offset starts from right to left
               ; hgfedcba
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

    call update_map

    call rotate90
    call update_map

    ; rotate90 overwrites map_enabled and map.
    ; That's why it calls rotate90 multiple times.
    call rotate90 ; 180
    call rotate90 ; 240
    call rotate90 ; 360

    ; Toggle player if the stone has enabled.
    bt [bx+3], cx
    jnc draw
    xor byte [2], 1
    jmp draw

    ; inverse
    mov di, askew.inc
    push ax
    xor ax, ax
    mov gs, ax
    pop ax
    call askew
    call update_map

    ; direct
    push cx
    abs cx, 7
    push ax
    mov ax, 7
    mov gs, ax
    pop ax
    mov di, askew.dec+0x7c00
    call askew
    pop cx
    push .inc_sidi_decdi+0x7c00
    call update_map


    .inc_sidi_decdi:
        push ax
        neg ax
        push cx
        neg cx
        push bx
        call askew.find_start
        add bx, ax
        call .make_sidi ; bx
        pop bx
        pop cx
        pop ax
    .end:
        ret
    .inc_sidi:
        push bx
        push cx
        call askew.find_start
        add bx, ax
        sub bl, cl
        call .make_sidi ; bx
        pop cx
        pop bx
        ret
    .make_sidi:
        lea si, [bx+3]
        ret

update_map:
    mov dl, 1
    call find
    mov dh, al
    neg dl
    call find
    cmp al, dh
    je .ret

    .loop:
        cmp al, dh
        jg .ret
        cmp byte [2], 0
        jnz .set_player2
        .set_player1:
            btr [bx+3+8], ax
            jmp .next
        .set_player2:
            bts [bx+3+8], ax
        .next:
            bts [bx+3], ax
        inc al
        jmp .loop
    .ret:
        ret

find:
    mov al, cl
    .loop:
        xor ah, ah
        add al, dl
        jl .restore
        cmp al, MAX_X
        jg .restore
        bt [bx+3], ax
        jnc .restore

        bt [bx+3+8], ax
        setc ah
        cmp ah, [2]
        jnz .loop

        xor ah, ah
        neg dl
        add al, dl
        ret

    .restore:
        mov al, cl
        ret

rotate90:
    mov si, 3
    call ._rotate90
    add si, 3+8
    call ._rotate90
    xchg cx, bx
    abs bx, MAX_X-1
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
    push bx
    push cx
    call .find_start
    mov si, map_enabled
    xor ax, ax
    .map_bitcheck:
        cmp bx, MAX_Y
        jge .end
        cmp cx, MAX_X
        jge .end
        bt [si+bx+MAX_Y], cx
        jnc .map_enabled_bitcheck
        bts ax, cx ; al = map
        .map_enabled_bitcheck:
            bt [si+bx], cx
            jnc .next
            xchg al, ah
            bts ax, cx ; ah = map_enabled
            xchg ah, al
        .next:
            inc bx
            call di
            js .end ; jump if .dec's retval < 0
            jmp .map_bitcheck
        .inc:
            inc cx
            ret
        .dec:
            dec cx
            ret
    .end:
        movzx si, ah
        movzx di, al
        pop cx
        pop bx
        ret
    .find_start:
        sub bx, cx
        js .set_cx
        mov cx, gs
        ret
        .set_cx:
            neg bx
            mov cx, bx
            mov bx, gs
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

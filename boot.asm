use16
org 0x7c00

other_msg: db "Message from first sectors!", 0
;primary_msg: db "============ Start OS ============", 0


_start:

xor ax, ax
mov ds, ax
mov es, ax
mov bp, 0x9000
mov sp, bp

mov ah, 0x0e 

mov si, other_msg
call print

;mov si, other_msg
;call print

main_loop:
    jmp main_loop   ; $ - Указатель на текущую инструкцию, данная конструкция означает вечный цикл  



; print(*message : si, len : di) -> void
print:
    push bp
    mov bp, sp
    .print_iter:
        mov al, [si]
        cmp al, 0
        je .exit

        int 0x10
        inc si
        jmp .print_iter


    .exit:
        mov sp, bp
        pop bp
        ret
    
; str_len(*str : si) -> len : dx
strlen:
    push bp
    mov bp, sp
    
    xor dx, dx
    .strlen_iter:
        mov al, [si]
        cmp al, 0
        je .exit

        inc si
        inc dx
        jmp .strlen_iter

    .exit:
        mov sp, bp
        pop bp
        ret
    

times 510 - ($ - $$) db 0 ; Заполняем оставшуюся память в программе (в секторе 512 байт) 0-ми

dw 0xaa55  ; Последние 2 байта должны содержать магические числа, так BIOS определяет какой 1-й сектор является загрузочным

; ================================================ Second Sector =================================================
second_sector:
    mov ah, 0x0e
    mov al, 'X'
    int 0x10
    mov al, 'X'
    int 0x10
    mov al, 'X'
    int 0x10

    jmp $

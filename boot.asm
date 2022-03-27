use16
org 0x7c00


primary_msg: db "============ Start OS ============", 0
disk_error_info: db "disk error!", 0
readed_data_from_disk: db "Readed data from Disk!", 0
module_address equ 0x1000 

_start:

xor ax, ax
mov ds, ax
mov es, ax
mov bp, 0x9000
mov sp, bp

mov ah, 0x0e 

mov si, primary_msg
mov di, 34 
call print

mov bx, module_address
mov dh, 2
call readf

call module_address

main_loop:
    jmp main_loop   ; $ - Указатель на текущую инструкцию, данная конструкция означает вечный цикл  



; readf()
readf:
    push bp
    mov bp, sp

    mov ah, 0x02 ; режим чтения с диска
    mov al, dh  ; количество считываемых сектором на диске
    mov ch, 0x00; номер цилиндра
    mov cl, 0x02; Номер сектора с которого начинается чтения остальных секторов
    mov dh, 0x00; Номер считывющей головки диска
    ; mov dl, dl; Номер устройства (идентификатор дсика). Его устанавливать незачем, читаем с тогоже утстройтсва 
    ; с которого загрузились
    int 0x13 ; Прерывание BIOS`а на чтение с диска
    jc .disk_error

    jmp .exit
    
    .disk_error:
        mov si, disk_error_info
        mov di, 12
        call print
    .exit:
        mov si, readed_data_from_disk
        mov di, 15
        call print
        mov sp, bp
        pop bp
        ret


; print(*message : si, len : di) -> void
print:
    push bp
    mov bp, sp
    .print_iter:
        mov al, [si]
        cmp di, 0
        je .exit

        int 0x10
        inc si
        dec di
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


second_sector:
    mov ah, 0x0e
    mov al, 'X'
    int 0x10
    mov al, 'X'
    int 0x10
    mov al, 'X'
    int 0x10

    jmp $

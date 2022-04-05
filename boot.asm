org 0x7c00 
mov [BOOT_DISK], dl ; Записываем номер устройства с которого мы загрузились в BOOT_DISK                 

                                    
xor ax, ax                          
mov es, ax
mov ds, ax
mov bp, 0x8000
mov sp, bp

mov bx, 0x7e00 ; в bx загружаем адрес куда будет записаны считываемые данные с диска
mov ah, 2 ; Номер прерывания bios`а для работы с диском (чтение с диска ah = 0x02)
mov al, 1 ; Количество считывемых с диска секторов 
mov ch, 0 ; Номер считываемого цилиндра
mov dh, 0 ; Номер считывающей головки
mov cl, 2 ; Номер считываемого сектора
mov dl, [BOOT_DISK] ; Номер дискового устроцства с которого будет производится чтение
int 0x13 ; Прерывание для работы с диском средаствами bios`а

mov ah, 0x0e ; Перекдючаем bios на работу дисплея в тестовом режиме

mov si, 0x7e00 ; Передаем в si адрес начала на память со считанными с диска данными
call print_str ; Вызываем функцию для вывода данных экран

jmp $

; print_str(si : char *str)
print_str:
    push bp
    mov bp, sp
    
    .print_iter:
        mov al, [si]
        cmp al, 0
        je .exit

        int 0x10
        inc si
        dec di
        jmp .print_iter 

    .exit:
        mov sp, bp
        pop bp
        ret


BOOT_DISK: db 0

times 510-($-$$) db 0              
dw 0xaa55

; ============================================== Start Second Sector ====================================
second_sector: db "ABCDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA Hello from second sector!", 0

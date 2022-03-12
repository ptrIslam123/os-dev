bits 16
org 0x7c00

; На данный момент нельзя размещать строку в определенной секции, иначе почемуто процессор не может получить к этому участку памяти доступ
; Сейчас строка определена в той же секции что и код програмы.
string1 db "Some string1", 0
string2 db "Some string2", 0
TrueStrMsg db "This strings is equals", 0
FalseStrMsg db "This strings is not equals", 0

section .text
global _start

_start:

    xor ax, ax ; Зануляем регист
    mov ds, ax ; Устанавливаем значение сегментного регистра DS(Data segment) сегмент данных
    mov es, ax ; Устанавливаем значение сегментного регистра ES(Extention segment) расширенный сегмент данных

    mov ah, 0x0e  ; Указываем режим работы BIOS с экраном монитора (он подерживает разные графические и текстовые режимы работы) 


    mov si, string1
    mov di, string2
    jmp compare_str

output_result:
    jmp print_true_message
    ;cmp ax, 0
    ;jne print_true_message
    ;jmp print_false_message



print_true_message:
    mov si, TrueStrMsg
    jmp print_str
    jmp main_loop

print_false_message:
    mov si, FalseStrMsg
    jmp print_str
    jmp main_loop



print_str: ; Процедура вывода строки на экран средствами BIOS
    print_cur_char_in_si_if_not_zero:
        mov al, [si] ; В регист al кладем разыменованный адрес, который хранится в регистре si (текущий символ строки байт)
        cmp al, 0 ;  Если значение этого байта равно 0
        je main_loop ; Прыгаем на указанную метку
        int 0x10 ; Иначе выводим указанный символ в al
        inc si ; Инкрементив указатель в регистре si на следующий байт
        jmp print_cur_char_in_si_if_not_zero    ; Прыгаем на начало цикла для вывода на экран следующего (уже текущего) символа строки




; Почему то не работает нормально, хотя по логике все должно работать корректно!!!
compare_str:
    ; Сигнатура: compare_str(string* str1=si, string* str2=di) int (ax=0 - False, ax=1 - True)
    compare_iter:
        mov ch, [si]
        mov dh, [di]
        cmp ch, dh
        jne not_equal

        cmp ch, 0
        je zero_equal

        inc si
        inc di
        jmp compare_iter

    not_equal:
        mov ax, 0
        jmp output_result
    
    zero_equal:
        cmp dh, 0
        jne not_equal
        mov ax, 1
        jmp output_result

main_loop:
    jmp main_loop   ; $ - Указатель на текущую инструкцию, данная конструкция означает вечный цикл  


times 510 - ($ - $$) db 0 ; Заполняем оставшуюся память в программе (в секторе 512 байт) 0-ми

dw 0xaa55  ; Последние 2 байта должны содержать магические числа, так BIOS определяет какой 1-й сектор является загрузочным
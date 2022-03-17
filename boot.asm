; 1) Необходимо загрузиться в реальном режиме.
; 2) Настройть сегментные регистры и стек.
; 3) Активировать шину адреса А20.
; 3.1) Дективировать не маскируемые прерывания.
; 4) Описать дескрипторную таблицу.
; 5) Загрузить в регистр GDTR адрес на начало дескрипторной таблицы и ее размер.
; 6) Установить первый бит PE регистра cr0
; 7) Совершить дальний переход, что бы заставить процессор загрузить в сегментный регистр CS значние смещения(значение индекса в таблице) на 
; дескриптор описывающий сегмент кода в дескрипторной тблице (селектор): 
;           jmp [занчение индекса дескриптора в таблице] : [нужное смещение в этом сегменте].
; 8) Проинициализировать в защищенном режиме остальные сегментные регистры (ds, es, ss, fs, gs) путем простой загрузки в эти регистры значений
;           индексов(смещения) в дескрипторной таблице, а так же стандартных атриюутов (TI, RPL).
; 9) Переити к выводу строки приветствия в защищенном режиме.

use16
org 0x7C00

__start:
    jmp far dword 0x0000:setup_segments

setup_segments:
    xor ax, ax
    mov ds, ax
    mov es, ax
    cli
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    jmp active_A20

active_A20:
    in  al, 0x92   
    or  al, 0x02
    out 0x92, al    

    ; Деактивация не маскируемых прерываний
    cli
    in  al, 0x70
    or  al, 0x80
    out 0x70, al

    jmp load_gdt

load_gdt:
    lgdt [gdt_entry]
    jmp active_cr0


active_cr0:
    ; Устанавливаем первый бит(PE - Protect Enable) регистра cr0 в 1 
    mov  eax, cr0  
    or   al,  0x01 
    mov  cr0, eax  
    ; После установки данного бита мы уже в защищенном режиме и нужно совершить первый дальний переход,
    ; который позволит записать в сегментный регистр CS индекс на дескриптор сегмента кода в дескрипторной таблице.
    ; 0000000000001000b is a segment selector which is loaded into CS register
    ; Segment selector's format:
    ;  [0:1]  RPL              = 00b            - requested privilege level = 0 (most privileged)
    ;      2  TI               = 0              - chooses descriptor table; 0 means Global Descriptor Table
    ; [3:15]  Descriptor Index = 0000000000001b - index of descriptor inside the descriptor table = 1

    jmp far dword 0000000000001000b:protection_mode_entry_point

use32
protection_mode_entry_point:
    mov ax, 0000000000010000b ; segment selector: RPL = 0, TI = 0, Descriptor Index = 2 (второй дескриптор описывает сегмент данных)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp kmain
 
 kmain:  
    ; Запись начала адреса видео памяти в регист edi
    mov edi, 0xB8000 
    mov esi, message    
    jmp print_str_in_pmode

print_str_in_pmode:
    ; Процесс вывода строки приветствия очень простой. Мы записываем в память итеративно сначало код выводимого символа(1 байт) а затем вторым 
    ; атрибуты символа(тоже 1 байт: 4 бита - цвет фона, 4 бита - цвет сивола).
    mov al, [esi]
    cmp al, 0
    je exit

    mov [edi], al
    inc edi
    inc esi
    mov al, 7
    mov [edi], al
    inc edi
    jmp print_str_in_pmode

exit:
    cli
    hlt


; Message-printing loop
message: db "Hello world from My OS in Protected mode!", 0

; Выравнивание по границе 8 байт для ускорения доступа к таблице
align 8
gdt_begin:
; Самая сложная часть программы (Нужно определить дескриптоную таблицу с 3 основными сегментами: 0 (первый) дескриптор не используется и к нему
; нельзя обращаться, 1 (второй) дскриптор будет описывать сегмент кода, 2 (третий) дескриптор будет описывать сегмент данных). Можно и больше
; дескрипторов, но дляминимальной работы нам этого хватит.

; Первый дескриптор (всегда нулевой и не используется)
NullDescriptor: db 8 dup(0)

; Второй дескриптор для сегмента кода
DescriptorForSegmentCode:
    dw 0xFFFF           ; Limit[0:15]
    db 0x00, 0x00, 0x00 ; Base[0:23]
    db 10011010b        ; P DPL[0:1] S Type[0:3]
    db 11001111b        ; G D/B L AVL Limit[16:19]
    db 0x00             ; Base[24:31]

    ; Detailed description of the segment descriptor:
    ; Base  = 0x00000000 - segment base address = 0
    ; Limit = 0xFFFFF    - segment size = 2^20
    ; P     = 1          - presence: segment is present in physical memory
    ; DPL   = 00b        - descriptor privilege level = 0 (most privileged)
    ; S     = 1          - system (TSS segment): segment is not a system segment
    ; Type  = 1010b      - code segment (1), C=0 R=1 A=0 execution and reading allowed
    ; G     = 1          - granularity: the size of the segment is measured in 4 kilobyte pages, i. e. it's equal to 2^20*4 KiB = 4 GiB
    ; D/B   = 1          - default size: operands and addresses are 32-bit wide
    ; L     = 0          - 64-bit code segment: in protected mode this bit is always zero
    ; AVL   = 0          - available: it's up to the programmer how to use this bit

; Третий дескриптор для сегмента данных (ds, es, ss, fs, gs)
DescriptorForSegmentData:
    dw 0xFFFF           ; Limit[0:15]
    db 0x00, 0x00, 0x00 ; Base[0:23]
    db 10010010b        ; P DPL[0:1] S Type[0:3]
    db 11001111b        ; G D/B L AVL Limit[16:19]
    db 0x00             ; Base[24:31]

    ; Detailed description of the segment descriptor:
    ; Base  = 0x00000000 - segment base address = 0
    ; Limit = 0xFFFFF    - segment size = 2^20
    ; P     = 1          - presence: segment is present in physical memory
    ; DPL   = 00b        - descriptor privilege level = 0 (most privileged)
    ; S     = 1          - system (TSS segment): segment is not a system segment
    ; Type  = 0010b      - data segment (0), E=0 W=1 A=0 reading and writing are allowed, expand-up data segment (offset ranges from 0 to Limit)
    ; G     = 1          - granularity: the size of the segment is measured in 4 kilobyte pages, i. e. it's equal to 2^20*4 KiB = 4 GiB
    ; D/B   = 1          - default size: stack pointer is 32-bit wide (concerns stack segment) and the upper bound of the segment is 4 GiB (concerns data segment)
    ; L     = 0          - 64-bit code segment: in protected mode this bit is always zero
    ; AVL   = 0          - available: it's up to the programmer how to use this bit

; Определяем размер таблицы дескрипторов
gdt_size equ $ - gdt_entry

; Указатель на размер(16 - бит) и начало(32 - бита) дескрипторной таблицы
gdt_entry:
    dw gdt_size - 1
    dd gdt_begin

signatura_for_BIOS:
    times 510 - ($ - $$) db 0 
    db 55h, 0AAh


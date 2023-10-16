use16
org 100h

;Смещение на символ - 2, на строку 0xA0
;В одной секунде 18.2 тика

main:
    mov ax, 0xb800      ;Кладём память видеоадаптера
    mov es, ax

    mov cx, 15
    line:
        mov ax, 15      ;Высчитываем столбец
        sub ax, cx
    
        call run_line_
        loop line
    xor ax, ax          ;Обнуляем АХ и завершаем выполнение программы
    int 16h
    int 20h



timeout:                ;Задержка в тиках
    pusha

    xor ah,ah           ;Обнуляем ah
    int 1ah             ;Читаем часы

    add dx, 2           ;Добавили к прочитанному времени задержку
    mov bx, dx          ;Записали в BX время начала задержки + задержку
    .wait:
    int 1ah             ;Читаем часы
    cmp dx, bx          ;Сравниваем нынешнее время с необходимым 
    jl .wait

    popa
    ret 

run_line_:               ;Проход по линии. В АХ номер линии.
    pusha

    mov bx, 0x2
    mul bx              ;Высчитываем смещение по столбцам
    mov di, ax          ;Указываем смещение

    mov cx, 31          ;Указываем количество сдвигов
    step:
        cmp cx, 24      ;Сравниваем положение
        ja move_upside  ;Ход в верхней части экрана

        cmp cx, 7       ;Сравниваем положение
        ja move_midside ;Ход в центральной части экрана
        jmp move_lastside;Ход в нижней части экрана
        
        goback:
        call timeout
        loop step

    popa
    ret

move_upside:
    push ax             ;Сохранили значение для восстановления в конце

    mov word[es:di],0x6F03;Запись в видеопамять
    add di, 0xA0        ;Сместились на строку

    pop ax              ;Возврат к первоначальным данным
    jmp goback

move_midside:
    push ax             ;Сохранили значение для восстановления в конце
    push cx

    mov word[es:di],0x6F03;Запись в видеопамять
    add di, 0xA0        ;Сместились на строку

    push di             ;Записали смещение "головы"
    mov dx, ax          ;Сохраняем смещение по столбцам
    mov ax, 8           ;Смещение вверх к "Хвосту"
    mov bx, 0xA0        ;Смещение на одну строку
    mul bx              ;Высчитываем смещение
    sub di, ax
    mov word[es:di], 0  ;Запись в видеопамять
    pop di              ;Возвращаемся к "голове"

    pop cx
    pop ax              ;Возврат к первоначальным данным
    jmp goback

move_lastside:
    push ax            ;Сохранили значение для восстановления в конце

    push di
    mov bx, 0xA0
    mov ax, cx
    mul bx
    sub di, ax
    mov word[es:di], 0 ;Запись в видеопамять
    pop di

    pop ax
    jmp goback
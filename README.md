<p align="center">
      <img src="https://i.ibb.co/VgqLdNG/lr-logo.png" width="726">
</p>

<p align="center">
   <img alt="Static Badge" src="https://img.shields.io/badge/Asm-FASM-blue?label=Asm&labelColor=%231303fc&color=%23ffffff">
</p>

# Условия задачи

Разработать программу "бегущей строки" на экране. Направление движения зависит от варианта. В моём случае движение сверху вниз.

# Разбор кода

## Блок main

Сам код:

```ASM
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
```

Рассмотрим его. `mov ax, 0xb800 и mov es,ax` задают сегмент памяти. В нашем случае, мы подготавливаемся обращаться к памяти видеоадаптера.

Далее идёт цикл. `mov cx, 15` - мы задаём кол-во столбцов, по которомым пробежится программа

`mov ax, 15 и sub ax, cx` - просчёт пробегаемого столбца. Например, если мы пробегаем второй столбец, значение `CX` будет равно ***14***, однако так как мы в `AX` всегда кладём ***15***,
в итоге в `AX` после вычитания будет лежать ***1***.

Дальше вызывается функция пробегания по столбцу, которую мы рассмотрим дальше. В самом конце блока - код завершения программы.
<br> <br> <br>

## Блок timeout

Эта функция отвечает за ожидание во время выполнения программы, код:

```ASM
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
```

Приниц организации задержки:

1. Читать время начала выполнения задержки.
2. Добавить к этому времени время задержки.
3. Читать время до тех пор, пока время не дойдёт до ***Время+Задержка***

Сначала `xor ah,ah` - обнуляет значения регистра (xor возвращает 1- когда биты разные, 0 - когда одинаковые. Так как операнды у нас одинаковые, все биты станут ***0***). Далее вызываем прерывание: оно прочитает время с часов и запишет в `DX`.
Далее добавляем к этому времени необходимое время ожидания (в тиках)

> В одной секунде 18.2 тика

Далее идёт блок .wait. В нем мы снова читаем часы, пока наше время не станет равным или больше, чем время с задержкой.

<br><br><br>

## Блок run_line

Код блока:

```ASM
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
```

Рассмотрим подробнее:

```ASM
mov bx, 0x2
mul bx              ;Высчитываем смещение по столбцам
mov di, ax          ;Указываем смещение
```

Здесь мы подсчитываем смещение для столбцов, чтобы попасть в нужную часть экрана.

```ASM
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
```

`mov cx, 31` - Количество шагов, которые необходимо сделать в столбце

Далее в цикле мы проверяем на какой части экрана в данный момент находится строка. Переходим по меткам, выполняя перемещение строки, вызываем функцию задержки, затем повторяем цикл.

## Блоки move

Рассмотрим блок, отвечающий за движение строки в верхней части экрана:

```ASM
move_upside:
    push ax             ;Сохранили значение для восстановления в конце

    mov word[es:di],0x6F03;Запись в видеопамять
    add di, 0xA0        ;Сместились на строку

    pop ax              ;Возврат к первоначальным данным
    jmp goback
```

Здесь мы записываем в память слово и меняем смещение.

<br><br>

Блок, отвечающий за движение строки в средней части экрана:

```ASM
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
```

Записываем слово в память. Дальше сохраняем смещение передней части, высчитываем смещения задней части, затираем конец, чтобы строка не увеличивалась в размерах. Возвращаем значение смещения передней части строки.

<br><br>

Блок, отвечающий за движение строки в нижней части экрана:

```ASM
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
```

Здесь мы считаем смещение для "хвоста" строки, кладём в ячейку памяти ***0***.

<br><br><br>

# Послесловие

В целом, данную программу можно написать разными способами. Другой вариант можно найти в репозиториях организации

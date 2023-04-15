%ifndef MACRO_PRINT_STC_ASM
%define MACRO_PRINT_STC_ASM

; Nie definiujemy tu żadnych stałych, żeby nie było konfliktu ze stałymi
; zdefiniowanymi w pliku włączającym ten plik.

section .rodata

section .data
    message db " stack=", 0  ; format string for printf, 10 is ASCII code for newline character
    end db 10,0
    Com dd 1             ; reserve quadword (8 bytes) for the number
    size dq 0 
    buf_size: equ 64
    newline: db 10

section .bss
    buf: resb buf_size

; Wypisuje napis podany jako pierwszy argument, a potem szesnastkowo zawartość
; rejestru podanego jako drugi argument i kończy znakiem nowej linii.
; Nie modyfikuje zawartości żadnego rejestru ogólnego przeznaczenia ani rejestru
; znaczników.

section .text
 extern prtt
 extern prtn

%macro printStc 0
  push    rax
  push    rcx
  push    rdx
  push    rsi
  push    rdi
  push r8
  push r9
  push    r10
  push    r12

  mov r12, r8

  mov [rel Com], dl         ; store the number in memory
  
  mov     eax, 1                  ; SYS_WRITE
  mov     edi, eax                ; STDOUT
  lea     rsi, [rel Com]      ; Napis jest w sekcji .text.
  mov     edx, 1 ; To jest długoś napisu.
  syscall


; print stack=
  mov     eax, 1                  ; SYS_WRITE
  mov     edi, eax                ; STDOUT
  lea     rsi, [rel message]      ; Napis jest w sekcji .text.
  mov     edx, 7 ; To jest długoś napisu.
  syscall

.start:
  cmp r12, 0
  je .endprtstck
  mov rdi, [rsp + 8*8 + r12*8]
  ; mov rdi, r10
  call prtt
  sub r12, 1
  jmp .start
.endprtstck:

  call prtn


  ; mov rdi, message       ; set format string as first argument to printf
  ; mov rsi, rdx         ; set the number as second argument to printf
  ; xor eax, eax           ; clear eax to indicate no floating point arguments
  ; call printf            ; call printf function



;   mov     rdx, [rsp + 72]         ; To jest wartość do wypisania.
;   mov     ecx, 16                 ; Pętla loop ma być wykonana 16 razy.
; %%next_digit:
;   mov     al, dl
;   and     al, 0Fh                 ; Pozostaw w al tylko jedną cyfrę.
;   cmp     al, 9
;   jbe     %%is_decimal_digit      ; Skocz, gdy 0 <= al <= 9.
;   add     al, 'A' - 10 - '0'      ; Wykona się, gdy 10 <= al <= 15.
; %%is_decimal_digit:
;   add     al, '0'                 ; Wartość '0' to kod ASCII zera.
;   mov     [rsp + rcx + 55], al    ; W al jest kod ASCII cyfry szesnastkowej.
;   shr     rdx, 4                  ; Przesuń rdx w prawo o jedną cyfrę.
;   loop    %%next_digit

;   mov     [rsp + 72], byte `\n`   ; Zakończ znakiem nowej linii. Intencjonalnie
;                                   ; nadpisuje na stosie niepotrzebną już wartość.

;   mov     eax, 1                  ; SYS_WRITE
;   mov     edi, eax                ; STDOUT
;   lea     rsi, [rsp + 56]         ; Bufor z napisem jest na stosie.
;   mov     edx, 17                 ; Napis ma 17 znaków.
;   syscall

  pop     r12
  pop     r10
  pop r9
  pop r8
  pop     rdi
  pop     rsi
  pop     rdx
  pop     rcx
  pop     rax
%endmacro

%endif

global core

; %include "macro_print.asm"
; %include "macro_print_stc.asm"

section .data
    changes:
        times N dq -1
    lowNrCore dq 0 ; space for exchange of value from lower nr core stack
    highNrCore dq 0; space for exchange of value from higher nr core stack 
    semaphore dd 1            ; Tylko jeden wątek może wejść.

section .text

  extern put_value
  extern get_value

; Dostaje w r9 adres semafora.
proberen:
  jmp     proberen_check
proberen_pause:
  pause
proberen_check:
  cmp     dword [r9], 0  ; Czekaj aktywnie, bez wywoływania operacji
  jle     proberen_pause  ; blokującej szynę (lock), aż semafor zostanie otwarty.
  mov     eax, -1
  lock \
  xadd    [r9], eax      ; Spróbuj wejść.
  test    eax, eax        ; Jeśli przed zmniejszeniem semafor był otwarty,
  jg      proberen_end    ; to oznacza, że się udało.
  lock \
  add     dword [r9], 1  ; Jeśli się nie udało, bo inny wątek był szybszy,
  jmp     proberen        ; to odwróć próbę wejścia i spróbuj ponownie.
proberen_end:
  ret

; Dostaje w r9 adres semafora.
verhogen:
  lock \
  add     dword [r9], 1  ; Zapewnij atomowe zwiększenie wartości semafora.
  ret

; rdi - n (core nr)
; rsi - *p pointer to string witch comands
; dl [rdx] - curent comand character
; rcx - tmp
; rbx - tmp2
; r8 working stack size
; r9 adress to semaphore
core:
; cmp rdi,0
;   jne .skipPrint0
;   print "start rbx = ", rbx
;   print "start rsp = ", rsp
; .skipPrint0:

  lea   r9, [rel semaphore]
  xor   r8, r8; zero working stack size
  xor   rdx,rdx 
  push  rbx ; save rbs as it's callee saved
.loop:
  mov   dl, byte[rsi] ; update crr comand character
; string ending character is 0 if dl ==0 then end
  cmp   dl,   0 
  je .core_end

;    cmp rdi,0
;   jne .skipPrint
;   printStc
; .skipPrint:

; add two values from stack when character is  +
  cmp   dl, '+'
  jne .ifmul
  pop   rax
  pop   rcx
  add   rax, rcx
  push  rax
  sub r8, 1

; multiply two values from stack when character is *
.ifmul:
  cmp   dl, '*' 
  jne .ifminu
  pop   rax
  pop   rcx
  imul  rcx
  push  rax
  sub r8, 1

; negate values from stack when character is -
.ifminu:
  cmp   dl, '-' 
  jne .ifnum
  pop   rax
  neg   rax
  push  rax

; add value to stack when character is digit
.ifnum:
  cmp   dl, '0'
  jl .ifn
  cmp   dl, '9'
  jg .ifn
  xor rax,rax
  mov al, dl
  sub al, '0'
  push rax
  add r8, 1

; add core nr to stack when character is n
.ifn:
  cmp   dl, 'n'
  jne .ifB
  push rdi
  add r8, 1

; conditional jump
.ifB:
  cmp   dl, 'B'
  jne .ifC 
  pop   rax
  pop   rcx ; read top of the stack
  push  rcx
  sub r8, 1 ; stack is shorter by 1
  cmp   rcx, 0; jump only if second value != 0
  je .ifC
  add   rsi, rax ; jump to correct instuction

; pop value from stack when character is C
.ifC:
  cmp    dl, 'C'
  jne .ifD
  pop rax
  sub r8, 1

; duplicate value from stack when character is D
.ifD:
  cmp    dl, 'D'
  jne .ifE
  pop   rax
  push  rax
  push  rax
  add r8, 1

; swap two top values from stack when character is E
.ifE:
  cmp   dl, 'E'
  jne .ifG
  pop   rax
  pop   rcx
  push  rax
  push  rcx

; call get_value when character is G
.ifG:
  cmp   dl, 'G'
  jne .ifP
  push rdi 
  push rsi
  push rdx
  push r8
  push r9

  push rbx ; save rbs as it's callee saved
  mov rbx, rsp ;save crr stack pointer
  and rsp, 0xfffffffffffffff0 ; change to zero last 4 bits decreseing stack pointer so it's divisible by 16

  call  get_value

  mov rsp, rbx ; change back to correct stack pointer
  pop rbx 

  pop r9
  pop r8
  pop rdx
  pop rsi
  pop rdi
  push rax ;add to stac redurned value from get_value
  add r8, 1

; rdi - n (core nr)
; rsi - *p pointer to string witch comands
; dl [rdx] - curent comand character
; rcx - tmp
; r9

; call put_value when character is P
.ifP:
  cmp   dl, 'P'
  jne .ifS
  pop rcx ; save stack top to tmp for function call
  push rdi 
  push rsi
  push rdx
  push r8
  push r9
  
  push rbx ; save rbs as it's callee saved
  mov rbx, rsp ;save crr stack pointer
  and rsp, 0xfffffffffffffff0 ; change to zero last 4 bits decreseing stack pointer so it's divisible by 16

  mov rsi, rcx
  call put_value

  mov rsp, rbx ; change back to correct stack pointer
  pop rbx 

  pop r9
  pop r8
  pop rdx
  pop rsi
  pop rdi
  sub r8, 1

; when character is S
.ifS:
  cmp   dl, 'S'
  jne .loop_end
  pop rcx ; nr of core to exchange
  shl rcx, 3 ; multiply nr of core by 8 so we have offset for array changes
  shl rdi, 3 ; multiply n by 8 so we have offset for array changes
  lea rbx, [rel changes] ; load addres of array changes
  cmp rdi, rcx
  jg .higherNr

;lower number core
  
  mov [rbx + rdi], rcx ; mark that core n is redy for exchange in array
  jmp .lowerNr
.lowerNrPause:
  pause
.lowerNr:
  cmp [rbx + rcx], rdi ; whait until core with higher number is ready in array
  jne .lowerNrPause
  ; print "lower after first ", rbx
  call proberen ; get mutex for exchange

  pop rax
  mov [rel lowNrCore], rax ; put value from stack to exchange
  mov qword [rbx + rcx], -1 ; signal other core that it's his time in array
.lowerNrPause2:
  pause
  cmp qword [rbx + rdi], -1 ; whait until other core is done in array
  jne .lowerNrPause2
  ; print "lower after second ", rbx
  mov rax, [rel highNrCore] ; get value from exchange
  push rax ; push value to stack

  call verhogen; release mutex afer exchange
  
  jmp .ifSEnd ; jump to end if your nr is smaller (skip code for higher nr core)

;higher number core
.higherNr:
  mov [rbx + rdi], rcx ; mark that core n is redy for exchange in array
.higherNrPause:
  pause
  cmp qword [rbx + rdi], -1 ; whait until other core did it thing in array
  jne .higherNrPause
  pop rax
  mov [rel highNrCore], rax ; put value from stack to exchange
  mov rax, [rel lowNrCore] ; get value from exchange
  push rax ; push value to stack
  mov qword [rbx + rcx], -1 ; signal other core that you are done in array

.ifSEnd:
  shr rdi, 3 ; chage back rdi so its equal to n
  sub r8, 1

.loop_end:
; next comad character
  inc rsi
  jmp .loop ; go back to the begining of the loop
  

.core_end:
  pop rax
  sub r8, 1
  shl r8, 3 ; multiply size of stack by 8 (bytes)
  add rsp, r8 ; set stack pointer to correct position
  pop rbx ; restore rbx
  ; print "end rbx = ", rbx
  ; print "end rsp = ", rsp
  ret


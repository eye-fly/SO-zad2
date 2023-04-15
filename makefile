
all: example

core.o: core.asm macro_print_stc.asm
	nasm -DN=2 -f elf64 -w+all -w+error -o core.o core.asm

# core.o: core.c
# 	gcc -c -Wall -Wextra -std=c17 -O2 -o core.o core.c

example.o: example.c
	gcc -c -Wall -Wextra -std=c17 -O2 -o example.o example.c

example: example.o core.o
	gcc -z noexecstack -o example core.o example.o -lpthread

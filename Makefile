CC     = gcc
CFLAGS = -std=c99 -ggdb3 -Wall -Wextra

SRC1 = src/prog_syscall.c
SRC2 = src/prog_glibc.c

prog_syscall:${SRC1}
	${CC} ${CFLAGS} -o ./bin/$@ $^

prog_glibc:${SRC2}
	${CC} ${CFLAGS} -o ./bin/$@ $^


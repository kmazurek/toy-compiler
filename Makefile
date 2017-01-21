CC=gcc -g -std=c99
CFLAGS=-lfl
OBJ= aug_parser.o aug_lexer.o

all: aug_compiler

aug_compiler: $(OBJ)
	$(CC) -o $@ $(OBJ) $(CFLAGS)

aug_lexer.c: aug_lexer.l
	flex -I -o aug_lexer.c aug_lexer.l

aug_parser.c: aug_parser.y
	bison -v -d -o aug_parser.c aug_parser.y

clean:
	rm -f aug_compiler
	rm -f *.c
	rm -f *.o
	rm -f *.h
	rm -f *~
	rm -f *.output
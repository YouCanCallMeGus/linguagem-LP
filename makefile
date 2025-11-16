CC = gcc
CFLAGS = -g -Wall
FLEX = flex
BISON = bison
LIBS = -lm

all: compilador

compilador: lex.yy.o parser.tab.o codegen.o
	$(CC) $(CFLAGS) -o $@ lex.yy.o parser.tab.o codegen.o $(LIBS)

lex.yy.o: lex.yy.c parser.tab.h
	$(CC) $(CFLAGS) -c lex.yy.c -o lex.yy.o

lex.yy.c: lexer.l
	$(FLEX) $<

parser.tab.o: parser.tab.c
	$(CC) $(CFLAGS) -c parser.tab.c -o parser.tab.o

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d -v $<

codegen.o: codegen.c codegen.h
	$(CC) $(CFLAGS) -c codegen.c -o codegen.o

test: compilador
	./compilador programa.esteira programa.asm
	@echo "📄 Assembly gerado:"
	@cat programa.asm

clean:
	rm -f lex.yy.c lex.yy.o parser.tab.c parser.tab.h parser.tab.o compilador *.o *.asm output *.output

.PHONY: all test clean
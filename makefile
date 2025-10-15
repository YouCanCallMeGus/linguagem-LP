all: lex.yy.c parser.tab.c parser.tab.h
	@echo "Análises geradas: lex.yy.c, parser.tab.c, parser.tab.h"

lex.yy.c: lexer.l
	flex lexer.l

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h
	@echo "Arquivos de análise removidos"

.PHONY: all clean
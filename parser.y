%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;

void yyerror(const char* s) {
    fprintf(stderr, "Erro: %s\n", s);
}

%}

%union {
    int number;
    char* string;
}

%token EXISTE SENDO RECEBE VELOCIDADE INCLINACAO
%token SE ENTAO DADOQUE PARATODO DE ATE PASSO
%token TEMPO INCLINACAOATUAL E OU
%token MENOR_IGUAL MAIOR_IGUAL IGUAL DIFERENTE
%token <number> NUMERO
%token <string> IDENTIFICADOR

%type <string> expressao termo declaracao atribuicao condicional enquanto paraTodo bloco comando programa

%%

programa:
    /* vazio */ { $$ = "programa_vazio"; }
    | programa comando { $$ = "programa_com_comando"; }
    ;

comando:
    declaracao
    | atribuicao
    | condicional
    | enquanto
    | paraTodo
    ;

declaracao:
    EXISTE IDENTIFICADOR SENDO expressao ';' {
        printf("Declaracao: %s = %s\n", $2, $4);
        free($2);
        free($4);
        $$ = "declaracao";
    }
    ;

atribuicao:
    VELOCIDADE RECEBE expressao ';' {
        printf("Atribuicao: velocidade = %s\n", $3);
        free($3);
        $$ = "atribuicao_velocidade";
    }
    | INCLINACAO RECEBE expressao ';' {
        printf("Atribuicao: inclinacao = %s\n", $3);
        free($3);
        $$ = "atribuicao_inclinacao";
    }
    | IDENTIFICADOR RECEBE expressao ';' {
        printf("Atribuicao: %s = %s\n", $1, $3);
        free($1);
        free($3);
        $$ = "atribuicao_variavel";
    }
    ;

condicional:
    SE expressao ENTAO bloco {
        printf("Condicional: se %s\n", $2);
        free($2);
        $$ = "condicional";
    }
    ;

enquanto:
    DADOQUE '(' expressao ')' bloco {
        printf("Loop enquanto: dadoQue %s\n", $3);
        free($3);
        $$ = "enquanto";
    }
    ;

paraTodo:
    PARATODO IDENTIFICADOR DE expressao ATE expressao bloco {
        printf("Loop paraTodo: %s de %s ate %s\n", $2, $4, $6);
        free($2); free($4); free($6);
        $$ = "paratodo_sem_passo";
    }
    | PARATODO IDENTIFICADOR DE expressao ATE expressao PASSO expressao bloco {
        printf("Loop paraTodo: %s de %s ate %s passo %s\n", $2, $4, $6, $8);
        free($2); free($4); free($6); free($8);
        $$ = "paratodo_com_passo";
    }
    ;

bloco:
    '{' programa '}' { $$ = "bloco"; }
    ;

expressao:
    termo { $$ = $1; }
    | expressao '+' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "(%s + %s)", $1, $3);
        free($1); free($3);
    }
    | expressao '-' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "(%s - %s)", $1, $3);
        free($1); free($3);
    }
    | expressao '*' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "(%s * %s)", $1, $3);
        free($1); free($3);
    }
    | expressao '/' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "(%s / %s)", $1, $3);
        free($1); free($3);
    }
    | expressao E termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "(%s E %s)", $1, $3);
        free($1); free($3);
    }
    | expressao OU termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "(%s OU %s)", $1, $3);
        free($1); free($3);
    }
    | expressao '<' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "(%s < %s)", $1, $3);
        free($1); free($3);
    }
    | expressao '>' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "(%s > %s)", $1, $3);
        free($1); free($3);
    }
    | expressao MENOR_IGUAL termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "(%s <= %s)", $1, $3);
        free($1); free($3);
    }
    | expressao MAIOR_IGUAL termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "(%s >= %s)", $1, $3);
        free($1); free($3);
    }
    | expressao IGUAL termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "(%s == %s)", $1, $3);
        free($1); free($3);
    }
    | expressao DIFERENTE termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "(%s != %s)", $1, $3);
        free($1); free($3);
    }
    ;

termo:
    NUMERO {
        $$ = malloc(20);
        sprintf($$, "%d", $1);
    }
    | IDENTIFICADOR { $$ = $1; }
    | TEMPO { $$ = strdup("tempo"); }
    | VELOCIDADE { $$ = strdup("velocidade"); }
    | INCLINACAOATUAL { $$ = strdup("inclinacaoAtual"); }
    | '(' expressao ')' { $$ = $2; }
    ;

%%

int main(int argc, char* argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            printf("Erro ao abrir arquivo: %s\n", argv[1]);
            return 1;
        }
    }
    
    yyparse();
    return 0;
}
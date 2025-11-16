%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "codegen.h"

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern char* yytext;

CodeGenerator* codegen;
int debug = 1;

void yyerror(const char* s) {
    fprintf(stderr, "Erro: %s na linha, token: '%s'\n", s, yytext);
}
%}

%union {
    int number;
    char* string;
}

%token EXISTE SENDO RECEBE VELOCIDADE INCLINACAO SE ENTAO
%token DADOQUE PARATODO DE ATE PASSO TEMPO INCLINACAO
%token E OU MENOR_IGUAL MAIOR_IGUAL IGUAL DIFERENTE
%token <number> NUMERO
%token <string> IDENTIFICADOR

%left OU
%left E
%left '+' '-'
%left '*' '/'
%nonassoc '<' '>' MENOR_IGUAL MAIOR_IGUAL IGUAL DIFERENTE

%type <string> programa comando declaracao atribuicao condicional enquanto paraTodo bloco expressao termo

%%

programa: 
    { /* programa vazio */ }
    | programa comando 
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
        if (debug) printf("Declaracao: %s = %s\n", $2, $4);
        codegen_declare_var(codegen, $2, $4);
        free($2); 
        free($4);
    }
    ;

atribuicao: 
    VELOCIDADE RECEBE expressao ';' {
        if (debug) printf("Atribuicao velocidade: %s\n", $3);
        codegen_assign_var(codegen, "velocidade", $3);
        free($3);
    }
    | INCLINACAO RECEBE expressao ';' {
        if (debug) printf("Atribuicao inclinacao: %s\n", $3);
        codegen_assign_var(codegen, "inclinacao", $3);
        free($3);
    }
    | TEMPO RECEBE expressao ';' {
        if (debug) printf("Atribuicao tempo: %s\n", $3);
        codegen_assign_var(codegen, "tempo", $3);
        free($3);
    }
    | IDENTIFICADOR RECEBE expressao ';' {
        if (debug) printf("Atribuicao variavel: %s = %s\n", $1, $3);
        codegen_assign_var(codegen, $1, $3);
        free($1); 
        free($3);
    }
    ;

condicional: 
    SE expressao ENTAO bloco {
        if (debug) printf("Condicional: se %s\n", $2);
        codegen_if_condition(codegen, $2); 
        codegen_comment(codegen, "Fim condicional");
        free($2);
    }
    ;

enquanto: 
    DADOQUE '(' expressao ')' {
        if (debug) printf("Loop enquanto: dadoQue %s\n", $3);
        codegen_while_start(codegen, $3);
        free($3);
    }
    bloco {
        codegen_while_end(codegen);
    }
    ;

paraTodo: 
    PARATODO IDENTIFICADOR DE expressao ATE expressao {
        if (debug) printf("Loop paraTodo: %s de %s ate %s\n", $2, $4, $6);
        codegen_for_start(codegen, $2, $4, $6, "1");
        free($2); 
        free($4); 
        free($6);
    }
    | PARATODO IDENTIFICADOR DE expressao ATE expressao PASSO expressao {
        if (debug) printf("Loop paraTodo: %s de %s ate %s passo %s\n", $2, $4, $6, $8);
        codegen_for_start(codegen, $2, $4, $6, $8);
        free($2); 
        free($4); 
        free($6);
        free($8);
    }
    bloco {
        codegen_for_end(codegen);
    }
    ;

bloco: 
    '{' programa '}' {
        if (debug) printf("Bloco executado\n");
    }
    ;

/* Expressões simplificadas e eficientes */
expressao: 
    termo { $$ = $1; }
    | expressao '+' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s+%s", $1, $3);
        free($1); free($3);
    }
    | expressao '-' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s-%s", $1, $3);
        free($1); free($3);
    }
    | expressao '*' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s*%s", $1, $3);
        free($1); free($3);
    }
    | expressao '/' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s/%s", $1, $3);
        free($1); free($3);
    }
    | expressao '<' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s<%s", $1, $3);
        free($1); free($3);
    }
    | expressao '>' termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s>%s", $1, $3);
        free($1); free($3);
    }
    | expressao MENOR_IGUAL termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "%s<=%s", $1, $3);
        free($1); free($3);
    }
    | expressao MAIOR_IGUAL termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "%s>=%s", $1, $3);
        free($1); free($3);
    }
    | expressao IGUAL termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "%s==%s", $1, $3);
        free($1); free($3);
    }
    | expressao DIFERENTE termo { 
        $$ = malloc(strlen($1) + strlen($3) + 5);
        sprintf($$, "%s!=%s", $1, $3);
        free($1); free($3);
    }
    | expressao E termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s E %s", $1, $3);
        free($1); free($3);
    }
    | expressao OU termo { 
        $$ = malloc(strlen($1) + strlen($3) + 4);
        sprintf($$, "%s OU %s", $1, $3);
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
    | INCLINACAO { $$ = strdup("inclinacao"); }  
    | '(' expressao ')' { $$ = $2; }
    ;

%%

int main(int argc, char* argv[]) {
    if (argc < 3) {
        printf("Uso: %s <arquivo_entrada> <arquivo_saida_asm>\n", argv[0]);
        printf("Ex: %s programa.esteira programa.asm\n", argv[0]);
        return 1;
    }
    
    codegen = codegen_init(argv[2]);
    
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        printf("Erro ao abrir arquivo: %s\n", argv[1]);
        return 1;
    }
    
    printf("Iniciando análise e geração de código...\n");
    codegen_comment(codegen, "Inicio do programa");
    
    int result = yyparse();
    
    if (result == 0) {
        codegen_comment(codegen, "Fim do programa");
        codegen_halt(codegen);
        printf("Compilacao concluída! Assembly gerado em: %s\n", argv[2]);
    } else {
        printf("Compilacao falhou com erros!\n");
    }
    
    fclose(yyin);
    codegen_free(codegen);
    
    return result;
}
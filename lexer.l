%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%%

[ \t\n]                 ;

"existe"               { return EXISTE; }
"sendo"                { return SENDO; }
"recebe"               { return RECEBE; }
"velocidade"           { return VELOCIDADE; }
"inclinacao"           { return INCLINACAO; }
"se"                   { return SE; }
"->ent"                { return ENTAO; }
"dadoQue"              { return DADOQUE; }
"paraTodo"             { return PARATODO; }
"de"                   { return DE; }
"ate"                  { return ATE; }
"passo"                { return PASSO; }
"tempo"                { return TEMPO; }
"inclinacaoAtual"      { return INCLINACAOATUAL; }
"E"                    { return E; }
"OU"                   { return OU; }

"<="                   { return MENOR_IGUAL; }
">="                   { return MAIOR_IGUAL; }
"=="                   { return IGUAL; }
"!="                   { return DIFERENTE; }
"<"                    { return '<'; }
">"                    { return '>'; }
"+"                    { return '+'; }
"-"                    { return '-'; }
"*"                    { return '*'; }
"/"                    { return '/'; }
"("                    { return '('; }
")"                    { return ')'; }
"{"                    { return '{'; }
"}"                    { return '}'; }
";"                    { return ';'; }

[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.string = strdup(yytext);
    return IDENTIFICADOR; 
}

[0-9]+                 {
    yylval.number = atoi(yytext);
    return NUMERO;
}

.                      { return yytext[0]; }

%%

int yywrap() {
    return 1;
}
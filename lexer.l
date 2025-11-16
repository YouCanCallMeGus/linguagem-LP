%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%option noyywrap nodefault

DIGITO    [0-9]
LETRA     [a-zA-Z_]
IDENT     {LETRA}({LETRA}|{DIGITO})*

%%

[ \t\n]                 { /* ignora */ }

"existe"               { printf("TOKEN: EXISTE\n"); return EXISTE; }
"sendo"                { printf("TOKEN: SENDO\n"); return SENDO; }
"recebe"               { printf("TOKEN: RECEBE\n"); return RECEBE; }
"velocidade"           { printf("TOKEN: VELOCIDADE\n"); return VELOCIDADE; }
"inclinacao"           { printf("TOKEN: INCLINACAO\n"); return INCLINACAO; }
"se"                   { printf("TOKEN: SE\n"); return SE; }
"->ent"                { printf("TOKEN: ENTAO\n"); return ENTAO; }
"dadoQue"              { printf("TOKEN: DADOQUE\n"); return DADOQUE; }
"paraTodo"             { printf("TOKEN: PARATODO\n"); return PARATODO; }
"de"                   { printf("TOKEN: DE\n"); return DE; }
"ate"                  { printf("TOKEN: ATE\n"); return ATE; }
"passo"                { printf("TOKEN: PASSO\n"); return PASSO; }
"tempo"                { printf("TOKEN: TEMPO\n"); return TEMPO; }
"E"                    { printf("TOKEN: E\n"); return E; }
"OU"                   { printf("TOKEN: OU\n"); return OU; }

"<="                   { printf("TOKEN: MENOR_IGUAL\n"); return MENOR_IGUAL; }
">="                   { printf("TOKEN: MAIOR_IGUAL\n"); return MAIOR_IGUAL; }
"=="                   { printf("TOKEN: IGUAL\n"); return IGUAL; }
"!="                   { printf("TOKEN: DIFERENTE\n"); return DIFERENTE; }
"<"                    { printf("TOKEN: <\n"); return '<'; }
">"                    { printf("TOKEN: >\n"); return '>'; }
"+"                    { printf("TOKEN: +\n"); return '+'; }
"-"                    { printf("TOKEN: -\n"); return '-'; }
"*"                    { printf("TOKEN: *\n"); return '*'; }
"/"                    { printf("TOKEN: /\n"); return '/'; }
"("                    { printf("TOKEN: (\n"); return '('; }
")"                    { printf("TOKEN: )\n"); return ')'; }
"{"                    { printf("TOKEN: {\n"); return '{'; }
"}"                    { printf("TOKEN: }\n"); return '}'; }
";"                    { printf("TOKEN: ;\n"); return ';'; }

{IDENT}               { 
    printf("TOKEN: IDENTIFICADOR '%s'\n", yytext);
    yylval.string = strdup(yytext);
    return IDENTIFICADOR; 
}

{DIGITO}+             {
    printf("TOKEN: NUMERO '%s'\n", yytext);
    yylval.number = atoi(yytext);
    return NUMERO;
}

.                     { 
    printf("TOKEN INVALIDO: '%c'\n", yytext[0]); 
    return yytext[0]; 
}

%%
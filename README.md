# linguagem-LP
Minha linguagem para a matéria de Linguagens e Paradigmas

### LMD
LMD é uma linguagem baseada nos termos de lógica e matemática discreta.

### VM
A VM é baseada numa esteira de academia, é possível controlar a velocidade, a inclinação e cronometrar o tempo.

```EBNF
programa          = { comando } ;

comando           = declaracao | atribuicao | condicional | enquanto | paraTodo ;

declaracao        = "existe" identificador "=" expressao ";" ;
atribuicao        = ("velocidade" | "inclinacao" | identificador) "=" expressao ";" ;

condicional       = "se" "(" expressao ")" "->ent:" bloco ;
enquanto          = "dadoQue" "(" expressao ")" ":" bloco ;

paraTodo          = "paraTodo" "(" inicializacao ";" expressao ";" incremento ")" ":" bloco ;
inicializacao     = identificador "=" expressao ;
incremento        = identificador ("++" | "+=" expressao | "--" | "-=" expressao) ;

bloco             = "{" { comando } "}" ;

expressao         = termo { ("+" | "-" | "*" | "/" | "E" | "OU" | "<" | ">" | "<=" | ">=" | "==" | "!=") termo } ;
termo              = numero | identificador | leitura | "(" expressao ")" ;

leitura             = "tempo" | "velocidade" | "inclinacaoAtual" ;

identificador       = letra { letra | digito | "_" } ;
numero               = digito { digito } ;
letra                = "a".."z" | "A".."Z" ;
digito               = "0".."9" ;

```

#### Mais detalhes:
comandos: 
- velocidade x; (define a velocidade do carro para x)
- inclinacao x; (define a inclinacao do carro para x)

sensores de leitura:
- tempo; (devolve o tempo atual da corrida em segundos)

### Exemplo de aplicação

```
existe i = 0;
existe tempoMaximo = 3600;
existe velocidadeMax = 30;
existe inclinacaoMax = 14;

dadoQue (tempo < tempoMaximo):
    velocidade += 0.1;
    inclinacaoAtual += 0.1;

    se (velocidade >= velocidadeMax) ->ent:
        velocidade = velocidadeMax;

    se (inclinacao >= inclinacaoMax) ->ent:
        inclinacao = inclinacaoMax;

```
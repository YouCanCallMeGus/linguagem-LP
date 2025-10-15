# linguagem-LP
Minha linguagem para a matéria de Linguagens e Paradigmas

### LMD
LMD é uma linguagem baseada nos termos de lógica e matemática discreta.

### VM
A VM é baseada numa esteira de academia, é possível controlar a velocidade, a inclinação e cronometrar o tempo.

```EBNF
programa          = { comando } ;

comando           = declaracao | atribuicao | condicional | enquanto | paraTodo ;

declaracao        = "existe" identificador "sendo" expressao ";" ;
atribuicao        = ("velocidade" | "inclinacao" | identificador) "recebe" expressao ";" ;

condicional       = "se" expressao "->ent" bloco ;
enquanto          = "dadoQue" "(" expressao ")" bloco ;

paraTodo          = "paraTodo" identificador "de" expressao "ate" expressao ["passo" expressao] bloco ;

bloco             = "{" { comando } "}" ;

expressao         = termo { ("+" | "-" | "*" | "/" | "E" | "OU" | "<" | ">" | "<=" | ">=" | "==" | "!=") termo } ;
termo             = numero | identificador | leitura | "(" expressao ")" ;

leitura           = "tempo" | "velocidade" | "inclinacaoAtual" ;

identificador     = letra { letra | digito | "_" } ;
numero            = digito { digito } ;
letra             = "a".."z" | "A".."Z" ;
digito            = "0".."9" ;
```

#### Mais detalhes:
comandos: 
- velocidade x; (define a velocidade do carro para x)
- inclinacao x; (define a inclinacao do carro para x)

sensores de leitura:
- tempo; (devolve o tempo atual da corrida em segundos)

### Exemplo de aplicação

```
existe i sendo 0;
existe tempoMaximo sendo 3600;
existe velocidadeMax sendo 30;
existe inclinacaoMax sendo 14;

dadoQue (tempo < tempoMaximo) {
    velocidade recebe velocidade + 0.1;
    inclinacao recebe inclinacao + 0.1;

    se velocidade >= velocidadeMax ->ent {
        velocidade recebe velocidadeMax;
    }

    se inclinacao >= inclinacaoMax ->ent {
        inclinacao recebe inclinacaoMax;
    }
}
```
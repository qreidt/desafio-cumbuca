# Notas de Desenvolvimento (Implementação Geral)

Antes de elaborar uma implementação, vou listar todos os requisitos encontrados em `DESAFIO.md`

## Requisitos

### 1. Identificar ID do Cliente

Ao enviar uma requisição, o cliente deve informar o seu id de cliente.

Não foi identificado o que deve-se ser feito caso não exista nenhuma informação no header,
então optei por retornar o http status 400 caso o não exista nenhuma informação no header.

### 2. Identificar comandos no body do request

Cada comando pode ou não receber outros parâmetros. Ientificando os possíveis tipos abaixo.
Caso o comando não esteja na lista abaixo, deverá ser necessário retornar a mensagem `No command <COMMAND>`
Caso os parâmetros do comando não tenham sido informados corretamente, retornar a mensagem `<COMMAND> <...PARAMS> - Syntax Error`.

Os possíveis comandos a serem recebidos são:

- **GET** <k: `str`>
Retornar valor armazenado para a chave `k`. Retornar `NIL` caso nenhum valor seja encontrado;
- **SET** <k: `str`> <v: `TRUE | FALSE | int | str`>
Armazenar o valor `v` para a chave `k`. Caso o valor `v` seja `NIL`, retornar a resposta `ERR "Cannot SET key to NIL"`;  (Sem status http diferente?)
- **BEGIN**
Iniciar uma transação. Caso uma transação já esteja aberta, retornar a resposta `ERR "Already in transaction"`; (Sem status http diferente?)
- **ROLLBACK**
Encerrar a transação sem persistir nenhuma das alterações. retornar um erro caso nenhuma transação esteja aberta;
- **COMMIT**
Encerrar a transação aberta, persistindo os dados da transação e liberando acesso para os demais usuários. Caso alguma das chaves da transação seja alterada, retornar uma mensagem de erro `ERR "Atomicity failure (teste)`.

## Exemplos
### SET
```mermaid
sequenceDiagram

    ClientA->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientA: 
    ClientA->>Server: Request: SET teste 2<br>Response: 1 2
    Server->>ClientA:  
```

### SET com valores incorretos

```mermaid
sequenceDiagram

    Note over ClientA, Server: key must always be a string
    ClientA->>Server: Request: SET 10 1<br>Response: ERR "Value 10 is not valid as key"
    Server->>ClientA: 
    
    Note over ClientA, Server: NIL never can be used as value to be set
    ClientA->>Server: Request: SET teste NIL<br>Response: ERR "Cannot SET key to NIL"
    Server->>ClientA: 
```

### GET
```mermaid
sequenceDiagram
    participant ClientA
    participant Server
    participant ClientB

    Note over ClientA, ClientB: Obs: Todos os usuários podem acessar o valor de<br>uma chave
    ClientA->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientA: 
    ClientA->>Server: Request: GET teste<br>Response: 1
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: 1
    Server->>ClientB: 
```

### GET com valores incorretos
```mermaid
sequenceDiagram
    participant ClientA
    participant Server

    Note over ClientA, Server: Um inteiro não é uma chave válida
    ClientA->>Server: Request: GET 10<br>Response: ERR "Value 10 is not valid as key"
    Server->>ClientA: 
    
    Note over ClientA, Server: NIL não é uma chave válida
    ClientA->>Server: Request: GET NIL<br>Response: ERR "Value NIL is not valid as key"
    Server->>ClientA: 
```

### BEGIN
```mermaid
sequenceDiagram
    participant ClientA
    participant Server
    participant ClientB

    Note over ClientA, ClientB: Outros clientes não poderão<br>visualizar alterações dentro da transação

    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: BEGIN<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: GET teste<br>Response: 1
    Server->>ClientA: 
```

```mermaid
sequenceDiagram
    participant ClientA
    participant Server

    Note over ClientA, Server: Não é possível abrir uma transação<br>dentro de uma transação<br>em andamento

    ClientA->>Server: Request: BEGIN<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: BEGIN<br>Response: ERR "Already in transaction"
    Server->>ClientA: 
```

```mermaid
sequenceDiagram
    participant ClientA
    participant Server
    participant ClientB

    Note over ClientA, ClientB: Em uma transação, alterações feitas por<br>outros usuários não são visíveis

    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: BEGIN<br>Response: OK
    Server->>ClientA: 
    ClientB->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientB: 
    ClientB->>Server: Request: GET teste<br>Response: 1
    Server->>ClientB: 
    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
```

### ROLLBACK
```mermaid
sequenceDiagram
    participant ClientA
    participant Server
    participant ClientB

    Note over ClientA, ClientB: Reverter todas as alterações da transação

    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: BEGIN<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: GET teste<br>Response: 1
    Server->>ClientA: 
    ClientA->>Server: Request: ROLLBACK<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
```

### COMMIT
```mermaid
sequenceDiagram
    participant ClientA
    participant Server
    participant ClientB

    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: BEGIN<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: GET teste<br>Response: 1
    Server->>ClientA: 
    ClientA->>Server: Request: COMMIT<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: GET teste<br>Response: 1
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: 1
    Server->>ClientB: 
```

```mermaid
sequenceDiagram
    participant ClientA
    participant Server
    participant ClientB
    
    note over ClientA,ClientB: Caso um valor lido na transação tenha sido alterado<br>o COMMIT falha

    ClientA->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientA->>Server: Request: BEGIN<br>Response: OK
    Server->>ClientA: 
    ClientA->>Server: Request: SET teste 1<br>Response: NIL 1
    Server->>ClientA: 
    ClientA->>Server: Request: GET teste<br>Response: 1
    Server->>ClientA: 
    ClientB->>Server: Request: GET teste<br>Response: NIL
    Server->>ClientB: 
    ClientB->>Server: Request: SET teste 10<br>Response: NIL 10
    Server->>ClientB: 
    ClientA->>Server: Request: COMMIT<br>Response: ERR "Atomicity failure (teste)"
    Server->>ClientA: 
    ClientA->>Server: Request: GET teste<br>Response: 10
    Server->>ClientA: 
    
    note over ClientA,ClientB: ?? O que fazer quando o último a ??<br>?? escrever for o cliente da transação ??
    
```
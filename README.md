# Desafio Cumbuca
Um banco de dados chave-valor transacional, persistente e multi-usuário, usando a linguagem Elixir e com
uma interface para comunicação HTTP.

Atualmente baseado apenas no uso de um Write-Ahead Log (WAL) mas que pode ser melhorado para ser baseado
em uma log-structured merge-tree (LSM-Tree).

Para interface WEB, o projeto foi baseado no framework Phoenix.

## Operação da interface WEB:
Para iniciar o servidor Phoenix no modo de desenvolvimento:
* Execute o comando `mix setup` para instalar e configurar dependências;
* Inicie o servidor Phoenix com o comando `mix phx.server` ou dentro do IEx com `iex -S mix phx.server`

A interface WEB estará disponível em [`127.0.0.1:4444`](http://127.0.0.1:4444).

Para executar a aplicação no modo de produção, você primeiro precisa seguir o
[guia de deploy para aplicações Phoenix](https://hexdocs.pm/phoenix/deployment.html)

## Interagindo com interface WEB
Antes de interagir com a interface web, lembre-se de definir o header X-Client-Name para ser possível ser
identificado.

### Criar ou atualizar um registro
```shell
# Inserir o valor ´1´ para a chave `ABC`.
curl --request POST \
  --url http://127.0.0.1:4444/ \
  --header 'X-Client-Name: Client-A' \
  --data 'SET ABC 1'
```

### Recuperar um registro
```shell
# Buscar o valor para a chave `ABC`.
curl --request POST \
  --url http://127.0.0.1:4444/ \
  --header 'X-Client-Name: Client-A' \
  --data 'GET ABC'
```

### Iniciar uma transação
```shell
curl --request POST \
  --url http://127.0.0.1:4444/ \
  --header 'X-Client-Name: Client-A' \
  --data 'BEGIN'
```

### Apagar dados de uma transação
```shell
curl --request POST \
  --url http://127.0.0.1:4444/ \
  --header 'X-Client-Name: Client-A' \
  --data 'BEGIN'
```

### Finalizar uma transação, persistindo dados
```shell
curl --request POST \
  --url http://127.0.0.1:4444/ \
  --header 'X-Client-Name: Client-A' \
  --data 'BEGIN'
```
## Armazenamento
Abaixo, exemplo de um `hexdump` do arquivo de log com os seguintes registros persistidos e como são compostos em disco:
1. ABC => 1
   - Tamanho da chave (uint16) 
   - Tamanho do valor (uint32)
   - Chave (3 chars)
   - Tipo do valor (int = 2) (uint8)
   - Valor do tipo inteiro (uint64)
2. ABC => 2
   - Tamanho da chave (uint16)
   - Tamanho do valor (uint32)
   - Chave (3 chars)
   - Tipo do valor (int = 2) (uint8)
   - Valor do tipo inteiro (uint64)
3. DEF => GHI
    - Tamanho da chave (uint16)
    - Tamanho do valor (uint32)
    - Chave (3 chars)
    - Tipo do valor (binary = 1) (uint8)
    - Valor do tipo string (3 chars)
4. JKL => true
    - Tamanho da chave (uint16)
    - Tamanho do valor (uint32)
    - Chave (3 chars)
    - Tipo do valor (bool = 3) (uint8)
    - Valor do tipo boolean (uint8)

![database.db hexdump](https://github.com/qreidt/desafio-cumbuca/blob/main/docs/images/hexdump.png?raw=true)

## Melhorias
A seguir estão passos de como melhorar o projeto:
- Utilizar [ETS (Erlang Term Storage)](https://hexdocs.pm/elixir/main/ets.html) para melhorar performance de caching
em um contexto distribuído;
- Implementar MemTables e SSTables (Tabelas de String Ordenadas) do LSM utilizando
[:gb_trees](https://www.erlang.org/doc/apps/stdlib/gb_trees.html) e refatorar módulo KV.Engine.Index para utilizar
summary tables e bloom filters e finalizar implementação de um LSM.

## Dev-logs
1. [Notas sobre a implementação](https://github.com/qreidt/desafio-cumbuca/blob/main/docs/dev-logs/01-implementa%C3%A7%C3%A3o-geral.md)
2. [Trabalhos para se basear](https://github.com/qreidt/desafio-cumbuca/blob/main/docs/dev-logs/02-trabalhos-semelhantes.md)
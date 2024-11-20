defmodule Kv.Command do

  @spec execute(binary()) :: {:error, binary()} | {:ok, binary()}
  def execute(complete_command) do
    [command, params] = split_command_and_params(complete_command)
    param_tokens = KV.Command.ParamTokenizer.tokenize(params)

    case command do
      "GET" -> execute(:GET, param_tokens)
      "SET" -> execute(:SET, param_tokens)
      "BEGIN" -> execute(:BEGIN, param_tokens)
      "ROLLBACK" -> execute(:ROLLBACK, param_tokens)
      "COMMIT" -> execute(:COMMIT, param_tokens)
      _ -> {:error, "Comando Desconhecido (#{command})"}
    end
  end

  # @spec split_command_and_params(binary()) :: [binary(), binary()]
  defp split_command_and_params(complete_command) do
    [command, params] = String.split(complete_command, " ", parts: 2)
    if is_list(params), do: [command, ""], else: [command, params]
  end

  # Validar e executar o comando GET
  defp execute(:GET, param_tokens) do
    with :ok <- validate_command(:GET, param_tokens) do
      {:ok, "-"}
    end
  end

  # Validar e executar o comando SET
  defp execute(:SET, param_tokens) do
    with :ok <- validate_command(:SET, param_tokens) do
      {:ok, "NIL -"}
    end
  end

  # Validar e executar o comando BEGIN
  defp execute(:BEGIN, param_tokens) do
    with :ok <- validate_command(:BEGIN, param_tokens) do
      {:ok, "OK"}
    end
  end

  # Validar o comando GET
  # O comando deve sempre receber apenas um parâmetro (<chave>)
  # O parâmetro <chave> deve ser uma string
  @spec validate_command(:GET, list()) :: :ok | {:err, binary()}
  def validate_command(:GET, param_tokens) do
    if length(param_tokens) == 1 and is_binary(Enum.at(param_tokens, 0)) do
      :ok
    else
      {:err, "GET <chave> - Syntax Error"}
    end
  end

  # Validar o comando SET
  # O comando deve sempre receber apenas 2 parâmetros (<chave> e <valor>)
  # O parâmetro <chave> deve ser uma string
  # O parâmetro <valor> pode ser uma string, um booleano ou um inteiro (todos menos :NIL)
  @spec validate_command(:SET, list()) :: :ok | {:err, binary()}
  def validate_command(:SET, param_tokens) do
    if (
      length(param_tokens) == 2 # Apenas 2 parâmetros
      and is_binary(Enum.at(param_tokens, 0)) # <chave> deve ser uma string
      and Enum.at(param_tokens, 1) != :NIL # <valor> não pode ser :NIL
    ) do
      :ok
    else
      {:err, "SET <chave> <valor> - Syntax Error"}
    end
  end

  # Validar o comando BEGIN
  # O comando não deve receber argumentos
  @spec validate_command(:BEGIN, list()) :: :ok | {:err, binary()}
  def validate_command(:BEGIN, param_tokens) do
    if length(param_tokens) == 0 do
      :ok
    else
      {:err, "BEGIN - Syntax Error"}
    end
  end
end

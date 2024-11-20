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

  defp execute(:GET, param_tokens) do
    with :ok <- validate_command(:GET, param_tokens) do
      {:ok, "-"}
    end
  end

  @spec validate_command(:GET, list()) :: :ok | {:err, binary()}
  def validate_command(:GET, param_tokens) do
    if length(param_tokens) == 1 and is_binary(Enum.at(param_tokens, 0)) do
      :ok
    else
      {:err, "ERR GET <chave> - Syntax Error"}
    end
  end
end

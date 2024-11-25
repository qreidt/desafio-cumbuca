defmodule KV.Command do
  alias KV.Engine

  @doc """
  Recebe a string completa do comando a ser executado, separa qual tipo de comando deve ser executado e realiza a validação dos parâmetros
  """
  @spec execute(binary(), binary()) :: {:err, binary()} | {:ok, binary()}
  def execute(client, complete_command) do
    [command, params] = split_command_and_params(complete_command)

    with {:ok, param_tokens} <- KV.Command.Parser.parse_params(params) do
      case command do
        "GET" -> execute(:GET, client, param_tokens)
        "SET" -> execute(:SET, client, param_tokens)
        "BEGIN" -> execute(:BEGIN, client, param_tokens)
        "ROLLBACK" -> execute(:ROLLBACK, client, param_tokens)
        "COMMIT" -> execute(:COMMIT, client, param_tokens)
        _ -> {:err, "ERR \"No command #{command}\""}
      end
    end
  end

  # @spec split_command_and_params(binary()) :: [binary(), binary()]
  defp split_command_and_params(complete_command) do
    with :nomatch <- :binary.match(complete_command, " ") do
      # Retornar string completa e sem parâmetros caso um espaço não tenha sido encontrado
      [complete_command, ""]
    else
      # Casp exista um espaço, realizar o split
      _ ->
        [command, params] = String.split(complete_command, " ", parts: 2)
        if is_list(params), do: [command, ""], else: [command, params]
    end
  end

  # Validar e executar o comando GET
  defp execute(:GET, client, param_tokens) do
    with :ok <- validate_command(:GET, param_tokens) do
      key = Enum.at(param_tokens, 0)
      value = Engine.get(client, key)
      {:ok, transform_value(value)}
    end
  end

  # Validar e executar o comando SET
  defp execute(:SET, client, param_tokens) do
    with :ok <- validate_command(:SET, param_tokens) do
      key = Enum.at(param_tokens, 0)
      value = Enum.at(param_tokens, 1)

      {old_value, inserted_value} = Engine.put(client, key, value)
      {:ok, "#{transform_value(old_value)} #{transform_value(inserted_value)}"}
    end
  end

  # Validar e executar o comando BEGIN
  defp execute(:BEGIN, client, param_tokens) do
    with :ok <- validate_command(:BEGIN, param_tokens) do
      case Engine.begin_transaction(client) do
        :ok -> {:ok, "OK"}
        {:error, :active_transaction} -> {:err, "ERR \"Already in transaction\""}
      end
    end
  end

  # Validar e executar o comando ROLLBACK
  defp execute(:ROLLBACK, client, param_tokens) do
    with :ok <- validate_command(:ROLLBACK, param_tokens) do
      case Engine.rollback_transaction(client) do
        :ok -> {:ok, "OK"}
        {:error, :no_active_transaction} -> {:err, "ERR \"No active transaction\""}
      end
    end
  end

  # Validar e executar o comando COMMIT
  defp execute(:COMMIT, client, param_tokens) do
    with :ok <- validate_command(:COMMIT, param_tokens) do
      case Engine.commit_transaction(client) do
        :ok -> {:ok, "OK"}
        {:error, :no_active_transaction} -> {:err, "ERR \"No active transaction\""}
        {:error, failed_keys} ->
          {:err, "ERR \"Atomicity failure (#{Enum.join(failed_keys, ", ")})\""}
      end
    end
  end

  #####
  ## Validação de Comandos
  #####

  def get_syntax_error_msg(), do: "ERR \"GET <chave> - Syntax Error\""
  def set_syntax_error_msg(), do: "ERR \"SET <chave> <valor> - Syntax Error\""
  def set_nil_value_error_msg(), do: "ERR \"Cannot SET key to NIL\""
  def begin_syntax_error_msg(), do: "ERR \"BEGIN - Syntax Error\""
  def rollback_syntax_error_msg(), do: "ERR \"ROLLBACK - Syntax Error\""
  def commit_syntax_error_msg(), do: "ERR \"COMMIT - Syntax Error\""

  # Validar o comando GET
  # O comando deve sempre receber apenas um parâmetro (<chave>)
  # O parâmetro <chave> deve ser uma string
  @spec validate_command(:GET, list()) :: :ok | {:err, binary()}
  def validate_command(:GET, param_tokens) do
    if length(param_tokens) == 1 and is_binary(Enum.at(param_tokens, 0)) do
      :ok
    else
      {:err, get_syntax_error_msg()}
    end
  end

  # Validar o comando SET
  # O comando deve sempre receber apenas 2 parâmetros (<chave> e <valor>)
  # O parâmetro <chave> deve ser uma string
  # O parâmetro <valor> pode ser uma string, um booleano ou um inteiro (todos menos :NIL)
  @spec validate_command(:SET, list()) :: :ok | {:err, binary()}
  def validate_command(:SET, param_tokens) do
    # Apenas 2 parâmetros
    # <chave> deve ser uma string
    if length(param_tokens) == 2 and
         is_binary(Enum.at(param_tokens, 0)) do
      # <valor> não pode ser nil
      if !is_nil(Enum.at(param_tokens, 1)), do: :ok, else: {:err, set_nil_value_error_msg()}
    else
      {:err, set_syntax_error_msg()}
    end
  end

  # Validar os comandos BEGIN, ROLLBACK e COMMIT
  # O comando não deve receber argumentos
  @spec validate_command(atom(), list()) :: :ok | {:err, binary()}
  def validate_command(command, param_tokens) when command in [:BEGIN, :ROLLBACK, :COMMIT] do
    if length(param_tokens) == 0 do
      :ok
    else
      {:err, "ERR \"#{to_string(command)} - Syntax Error\""}
    end
  end

  defp transform_value(value) when is_nil(value) do
    "NIL"
  end

  defp transform_value(value) when is_integer(value) do
    to_string(value)
  end

  defp transform_value(value) when is_boolean(value) do
    if value, do: "TRUE", else: "FALSE"
  end

  defp transform_value(value) do
    value
  end
end

defmodule KV.Command do

  @doc """
  Recebe a string completa do comando a ser executado, separa qual tipo de comando deve ser executado e realiza a validação dos parâmetros
  """
  @spec execute(binary()) :: {:error, binary()} | {:ok, binary()}
  def execute(complete_command) do
    [command, params] = split_command_and_params(complete_command)

    with {:ok, param_tokens} <- KV.Command.Parser.parse_params(params) do
      case command do
        "GET" -> execute(:GET, param_tokens)
        "SET" -> execute(:SET, param_tokens)
        "BEGIN" -> execute(:BEGIN, param_tokens)
        "ROLLBACK" -> execute(:ROLLBACK, param_tokens)
        "COMMIT" -> execute(:COMMIT, param_tokens)
        _ -> {:error, "Comando Desconhecido (#{command})"}
      end
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

  # Validar e executar o comando ROLLBACK
  defp execute(:ROLLBACK, param_tokens) do
    with :ok <- validate_command(:ROLLBACK, param_tokens) do
      {:ok, "OK"}
    end
  end

  # Validar e executar o comando COMMIT
  defp execute(:COMMIT, param_tokens) do
    with :ok <- validate_command(:COMMIT, param_tokens) do
      {:ok, "OK"}
    end
  end

  #####
  ## Validação de Comandos
  #####

  def get_syntax_error_msg(), do: "GET <chave> - Syntax Error"
  def set_syntax_error_msg(), do: "SET <chave> <valor> - Syntax Error"
  def set_nil_value_error_msg(), do: "Cannot SET key to NIL"
  def begin_syntax_error_msg(), do: "BEGIN - Syntax Error"
  def rollback_syntax_error_msg(), do: "ROLLBACK - Syntax Error"
  def commit_syntax_error_msg(), do: "COMMIT - Syntax Error"


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
    if (
      length(param_tokens) == 2 # Apenas 2 parâmetros
      and is_binary(Enum.at(param_tokens, 0)) # <chave> deve ser uma string
    ) do
      # <valor> não pode ser :NIL
      if ! is_nil(Enum.at(param_tokens, 1)), do: :ok, else: {:err, set_nil_value_error_msg()}
    else
      {:err, set_syntax_error_msg()}
    end
  end

  # Validar os comandos BEGIN, ROLLBACK e COMMIT
  # O comando não deve receber argumentos
  @spec validate_command(atom(), list()) :: :ok | {:err, binary()}
  def validate_command(command, param_tokens) when (command in [:BEGIN, :ROLLBACK, :COMMIT]) do
    if length(param_tokens) == 0 do
      :ok
    else
      {:err, "#{to_string(command)} - Syntax Error"}
    end
  end
end

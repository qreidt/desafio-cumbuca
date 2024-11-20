defmodule KV.Command.Parser do
  @boolean_values ["TRUE", "FALSE"]

  @spec parse_params(any()) :: {:ok, []}
  @doc """
  Recebe uma string contendo os parâmetros de comandos e deve validar a string
  e retornar a sequência de valores dos parâmetros

  ### Examples
    iex> parse_string("ABC")
    {:ok, ["ABC"]}

    iex> parse_string("\"ABC\"")
    {:ok. ["ABC"]}

    iex> parse_string("你好")
    {:ok. ["你好"]}

    iex> parse_string("TRUE")
    {:ok. [:TRUE]}

    iex> parse_string("\"TRUE\"")
    {:ok. ["TRUE"]}

    iex> parse_string("AB C")
    {:ok. ["AB", "C"]}

    iex> parse_string("\"AB C\"")
    {:ok. ["AB C"]}

    iex> parse_string("\"AB\"C\"")
    {:err. :syntax_error}

    iex> parse_string("\"AB\\\"C\"")
    {:ok. ["AB\"C"]}

    iex> parse_string("a10")
    {:ok. ["a10"]}

    iex> parse_string("10a")
    {:ok. ["10a"]}

    iex> parse_string("10")
    {:ok. [10]}
  """
  def parse_params(param_string) when is_binary(param_string) do
    case KV.Command.ParamTokenizer.tokenize(param_string) do
      :err -> {:err, :syntax_error}
      tokens -> Enum.map(tokens, &parse_token/1)
        |> handle_parsing_result()
    end
  end

  @spec parse_token(binary()) :: {:err, :unclosed_string} | {:ok, any()}
  @doc """
  Realiza a conversão e validação para cada token coletado
  """
  def parse_token(token) do
    cond do
      is_boolean_token?(token) -> {:ok, parse_boolean(token)}
      is_integer_token?(token) -> {:ok, String.to_integer(token)}
      is_nil_token?(token) -> {:ok, :nil}
      is_quoted_string?(token) -> {:ok, parse_quoted_string(token)}
      true -> {:ok, token}
    end
  end

  # Validating Boolean
  defp is_boolean_token?(token), do: token in @boolean_values

  defp parse_boolean("TRUE"), do: :TRUE
  defp parse_boolean("FALSE"), do: :FALSE

  # Validating Integer
  defp is_integer_token?(token), do: String.match?(token, ~r/^\d+$/)

  # Validating NIL
  defp is_nil_token?(token), do: token == "NIL"

  # Validating Quoted Strings
  defp is_quoted_string?(token) do
    String.starts_with?(token, "\"") and String.ends_with?(token, "\"")
  end

  defp parse_quoted_string(token) do
    String.slice(token, 1..-2//1)
  end

  # Handle any errors in tokens
  defp handle_parsing_result(results) do
    case Enum.find(results, fn result -> match?({:err, _}, result) end) do
      {:err, reason} -> {:err, reason}
      nil -> {:ok, Enum.map(results, fn {:ok, value} -> value end)}
    end
  end
end

defmodule KV.CommandParser do

  @doc """
  Recebe uma string contendo os parâmetros de comandos e deve validar a string
  e retornar a sequência de valores dos parâmetros

  ## Examples
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
    {:err. :unclosed_string}

    iex> parse_string("\"AB\\\"C\"")
    {:ok. ["AB\"C"]}

    iex> parse_string("a10")
    {:ok. ["a10"]}

    iex> parse_string("10a")
    {:ok. ["10a"]}

    iex> parse_string("10")
    {:ok. [10]}
  """
  def parse_params(_param_string) do
    {:ok, []}
  end

  @doc """
  Recebe uma sequência de caracteres e deve retornar qual o seu tipo

  ## Exemplos
    iex> get_value_type("ABC")
    :string

    iex> get_value_type("TRUE")
    :TRUE

    iex> get_value_type("10")
    :int

    iex> get_value_type("NIL")
    :NIL

    iex> get_value_type("10a")
    :string
  """
  def get_value_type(_string) do
    :string
  end
end

defmodule KV.Engine.Writer do
  use GenServer

  alias KV.Engine.Index

  @binary_type_value_map %{
    # nil: 0,
    string: 1,
    integer: 2,
    bool: 3,
  }

  # Iniciar GenServer com caminho para arquivo de log
  def start_link(log_path) do
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
  end

  # Criar e/ou abrir arquivo no local dado
  def init(log_path) do
    fd = File.open!(log_path, [:write, :binary]) # Debug
    # fd = File.open!(log_path, [:read, :write, :binary])
    {:ok, %{fd: fd, current_offset: 0}}
  end

  # Inserir ou atualizar uma chave com um valor
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def get_current_offset() do
    GenServer.call(__MODULE__, :get_current_offset)
  end

  # Inserir dados no arquivo de destivo
  # Atualizar índice e atualizar estado do GenServer
  def handle_call({:put, key, value}, _from, %{fd: fd, current_offset: current_offset} = state) do

    # Converter chave e valor para um registro binário e obter offset
    {data, value_rel_offset, value_size} = kv_to_binary(key, value)

    # Escrever registro no arquivo de log
    :ok = IO.binwrite(fd, data)

    # Calcular offset absoluto do valor do registro
    value_offset = current_offset + value_rel_offset

    # Atualizar índice com offset e tamanho do valor do registro
    Index.update(key, value_offset, value_size)

    # Atualizar estado
    new_state = %{state | current_offset: value_offset + value_size}
    {:reply, {:ok, {value_offset, value_size}}, new_state}
  end

  # Retorna o valor do offset atual
  def handle_call(:get_current_offset, _from, %{current_offset: current_offset} = state) do
    {:reply, current_offset, state}
  end

  # Codifica os valores de chave e valor para binário.
  defp kv_to_binary(key, value) do
    # Obter tamanho em bytes da chave e converter em um uint16
    key_size = byte_size(key)
    key_size_data = <<key_size::big-unsigned-integer-16>>

    # Obter tamanho em bytes do valor e converter para binário
    {value_size, value_size_data, value_data} = value_to_binary(value)

    # Converter tamanho do conteúdo a ser armazenado em binário
    sizes_data = <<key_size_data::binary, value_size_data::binary>>

    # Converter registro a ser armazenado em binário
    kv_data = <<key::binary, value_data::bitstring>>

    # Unificar sequência binária a ser armazenado
    data = <<sizes_data::binary, kv_data::bitstring>>

    # Calcular tamanho do cabeçalho antes de chegar no valor
    value_relative_offset = byte_size(sizes_data) + key_size

    {data, value_relative_offset, value_size}
  end

  # Obter tamanho em bytes do valor em uint32 e converter o valor para bitstring
  defp value_to_binary(value) when is_binary(value) do
    value_size = byte_size(value) + 1 # string length + 1 byte
    value_size_data = <<value_size::big-unsigned-integer-32>>

    type = @binary_type_value_map.string

    value_data = <<type::8, value::binary>>
    {value_size, value_size_data, value_data}
  end

  # Converter o valor para uma bitstring
  defp value_to_binary(value) when is_integer(value) do
    value_size = 9 # uint64 + 8bits = 9 bytes
    value_size_data = <<value_size::big-unsigned-integer-32>>

    type = @binary_type_value_map.integer

    value_data = <<type::8, value::unsigned-big-integer-64>>
    {value_size, value_size_data, value_data}
  end

  # Obter tamanho em bytes do valor em uint32 e converter o valor para binário
  defp value_to_binary(value) when is_boolean(value) do
    value_size = 2 # 1 byte + 1byte
    value_size_data = <<value_size::big-unsigned-integer-32>>

    type = @binary_type_value_map.bool
    value_int = if value, do: 1, else: 0

    value_data = <<type::8, value_int::8>>
    {value_size, value_size_data, value_data}
  end
end

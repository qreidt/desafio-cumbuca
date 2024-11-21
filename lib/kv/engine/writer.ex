defmodule KV.Engine.Writer do
  use GenServer

  alias KV.Engine.Index

  # Iniciar GenServer com caminho para arquivo de log
  def start_link(log_path) do
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
  end

  # Criar e/ou abrir arquivo no local dado
  def init(log_path) do
    fd = File.open!(log_path, [:write, :binary])
    {:ok, %{fd: fd, current_offset: 0}}
  end

  # Inserir ou atualizar uma chave com um valor
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  # Inserir dados no arquivo de destivo
  # Atualizar índice e atualizar estado do GenServer
  def handle_call({:put, key, value}, _from, %{fd: fd, current_offset: current_offset} = state) do
    {data, value_rel_offset, value_size} = kv_to_binary(key, value)


    :ok = IO.binwrite(fd, data)

    value_offset = current_offset + value_rel_offset
    Index.update(key, value_offset, value_size)

    new_state = %{state | current_offset: value_offset + value_size}
    {:reply, {:ok, {value_offset, value_size}}, new_state}
  end

  # Codifica os valores de chave e valor para binário.
  defp kv_to_binary(key, value) do
    timestamp = :os.system_time(:millisecond)
    timestamp_data = <<timestamp::big-unsigned-integer-size(64)>>

    key_size = byte_size(key)
    value_size = byte_size(value)

    key_size_data = <<key_size::big-unsigned-integer-16>>
    value_size_data = <<value_size::big-unsigned-integer-32>>
    sizes_data = <<key_size_data::binary, value_size_data::binary>>

    kv_data = <<key::binary, value::binary>>

    data = <<timestamp_data::binary, sizes_data::binary, kv_data::binary>>

    value_relative_offset = byte_size(timestamp_data) + byte_size(sizes_data) + key_size

    {data, value_relative_offset, value_size}
  end
end

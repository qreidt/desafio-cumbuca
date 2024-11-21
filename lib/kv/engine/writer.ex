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
    :ok = IO.binwrite(fd, value)
    size = byte_size(value)

    Index.update(key, current_offset, size)

    new_state = %{state | current_offset: current_offset + size}
    {:reply, {:ok, {current_offset, size}}, new_state}
  end
end

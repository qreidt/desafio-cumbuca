defmodule KV.Engine.Index do

  use GenServer

  # Iniciar o GenServer com Map vazio
  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, name: __MODULE__)
  end

  def start_link(log_path) when is_binary(log_path) do
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
  end

  def init(:empty), do: {:ok, %{}}

  # Criar e/ou abrir arquivo no local dado
  def init(log_path) do
    with {:ok, fd} <- File.open(log_path, [:read, :binary]),
       {_current_offset, offsets} = load_offsets(fd)
    do
      File.close(fd)
      {:ok, offsets}
    else
      _ -> init(:empty)
    end
  end

  ###########
  ## Public API
  ###########

  def update(key, offset, size) do
    GenServer.call(__MODULE__, {:update, key, offset, size})
  end

  @spec lookup(binary()) :: {:ok, {integer(), integer()}} | {:error, :not_found}
  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  ###########
  ## GenServer Commands
  ###########

  # Atualiza uma chave no index do GenServer
  def handle_call({:update, key, offset, size}, _from, index_map) do
    {:reply, :ok, Map.put(index_map, key, {offset, size})}
  end

  # Recebe uma chave e retorna o valor para aquela respectiva chave
  def handle_call({:lookup, key}, _from, index_map) do
    {:reply, get_key_offset_size(key, index_map), index_map}
  end

  # Helper para determinar o indice para um novo insert
  # Retorna {:ok, offset_size} se a chave existir ou {:error, :not_found} caso não exista
  defp get_key_offset_size(key, index_map) do
    case Map.get(index_map, key) do
      {_offset, _size} = offset_size -> {:ok, offset_size}
      nil -> {:error, :not_found}
    end
  end

  # Reconstruír índices do arquivo em memória
  defp load_offsets(fd, offsets \\ %{}, current_offset \\ 0) do
    # Posicionar reader no offset inicial de cada registro
    :file.position(fd, current_offset)

    # Ler conteúdo do registro
    with <<key_size::big-unsigned-integer-16>> <- IO.binread(fd, 2),
      <<value_size::big-unsigned-integer-32>> <- IO.binread(fd, 4),
      key <- IO.binread(fd, key_size)
    do

      # Recalcular offset absoluto do valor do registro
      value_absolute_offset = current_offset + 6 + key_size

      # Atualizar índice com registro
      offsets = Map.put(offsets, key, {value_absolute_offset, value_size})

      # Atualizar o próximo registro
      load_offsets(fd, offsets, value_absolute_offset + value_size)
    else
      :eof -> {current_offset, offsets}
    end
  end

end

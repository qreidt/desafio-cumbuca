defmodule KV.Engine.Index do

  use GenServer

  # Iniciar o GenServer com Map vazio
  def start_link([]) do
    GenServer.start_link(__MODULE__, :empty, name: __MODULE__)
  end

  def init(:empty), do: {:ok, %{}}


  ###########
  ## Public API
  ###########

  # Public API function to update the index with a new key-value pair.
  # Sends a synchronous call to the GenServer with the `:update` command
  # and the specified key, offset, and size.
  def update(key, offset, size) do
    GenServer.call(__MODULE__, {:update, key, offset, size})
  end

  # Public API function to look up a key in the index.
  # Sends a synchronous call to the GenServer with the `:lookup` command
  # and the specified key.
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
    IO.inspect({key, index_map})
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

end

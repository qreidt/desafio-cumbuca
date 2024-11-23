defmodule KV.Engine do

  use GenServer

  alias KV.Engine.{Index, Writer, Reader}

  # Iniciar GenServer com caminho para arquivo de log
  @spec start_link() :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(log_path \\ "data/database.db") do
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
  end

  def init(log_path) do
    Index.start_link(log_path)
    Writer.start_link(log_path)
    {:ok, reader_pid} = Reader.start_link(log_path)

    {:ok, %{reader_pid: reader_pid}}
  end


  ###########
  ## Public API
  ###########

  @spec put(binary(), binary()|integer()|boolean()) :: {nil|binary()|integer()|boolean(), binary()|integer()|boolean()}
  @doc """
  Inserir ou atualizar um registro
  Retorna o registro anterior e o valor recém inserido
  """
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @doc """
  Retornar o valor armazenado para a chave informada. Retnorar nil caso nenhum valor seja encontrado
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end


  ###########
  ## GenServer Commands
  ###########

  def handle_call({:put, key, value}, _from, state) do
    current_value = get_key_current_value(key, state.reader_pid)
    Writer.put(key, value)

    {:reply, {current_value, value}, state}
  end

  def handle_call({:get, key}, _from, state) do
    current_value = get_key_current_value(key, state.reader_pid)
    {:reply, current_value, state}
  end

  defp get_key_current_value(key, reader_pid) do
    case Reader.get(reader_pid, key) do
      {:ok, value} -> value
      _error -> nil
    end
  end
end

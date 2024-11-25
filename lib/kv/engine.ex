defmodule KV.Engine do
  use GenServer

  alias KV.Engine.{Index, Writer, Reader, TransactionManager}

  @type input_value :: binary() | integer() | boolean()
  @type output_value :: nil | input_value()

  # Iniciar GenServer com caminho para arquivo de log
  @spec start_link() :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts \\ []) do
    log_path = Application.get_env(:phoenix, :log_path)
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
  end

  def init(log_path) do
    Index.start_link(log_path)
    Writer.start_link(log_path)
    {:ok, reader_pid} = Reader.start_link(log_path)

    {:ok,
     %{
       reader_pid: reader_pid,
       transactions: %{}
     }}
  end

  ###########
  ## Public API
  ###########

  @spec put(binary(), binary(), input_value()) ::
          {output_value(), binary() | integer() | boolean()}
  @doc """
  Inserir ou atualizar um registro
  Retorna o registro anterior e o valor recém inserido
  """
  def put(client, key, value) do
    GenServer.call(__MODULE__, {:put, client, key, value})
  end

  @spec get(binary(), binary()) :: output_value()
  @doc """
  Retornar o valor armazenado para a chave informada. Retnorar nil caso nenhum valor seja encontrado
  """
  def get(client, key) do
    GenServer.call(__MODULE__, {:get, client, key})
  end

  @spec begin_transaction(binary()) :: :ok | {:error, :active_transaction}
  def begin_transaction(client) do
    GenServer.call(__MODULE__, {:begin_transaction, client})
  end

  @spec rollback_transaction(binary()) :: :ok | {:error, :no_active_transaction}
  def rollback_transaction(client) do
    GenServer.call(__MODULE__, {:rollback_transaction, client})
  end

  @spec commit_transaction(binary()) :: :ok | {:error, [binary()]} | {:error, :no_active_transaction}
  def commit_transaction(client) do
    GenServer.call(__MODULE__, {:commit_transaction, client})
  end

  ###########
  ## GenServer Commands
  ###########

  def handle_call({:put, client, key, value}, _from, state) do
    %{transactions: transactions, reader_pid: reader_pid} = state

    if client_has_transaction?(client, transactions) do
      {old_value, updated_transactions_map} =
        TransactionManager.put(client, key, value, transactions, fn ->
          get_key_current_value(key, reader_pid)
        end)

      {:reply, {old_value, value}, %{state | transactions: updated_transactions_map}}
    else
      old_value = get_key_current_value(key, reader_pid)
      Writer.put(key, value)

      {:reply, {old_value, value}, state}
    end
  end

  def handle_call({:get, client, key}, _from, %{transactions: transactions} = state) do
    current_value =
      if client_has_transaction?(client, transactions) do
        client_transaction = Map.get(transactions, client)
        Map.get(client_transaction.values, key)
      else
        get_key_current_value(key, state.reader_pid)
      end

    {:reply, current_value, state}
  end

  def handle_call({:begin_transaction, client}, _from, state) do
    if client_has_transaction?(client, state.transactions) do
      {:reply, {:error, :active_transaction}, state}
    else
      transactions = new_transaction(client, state.transactions)
      {:reply, :ok, %{state | transactions: transactions}}
    end
  end

  def handle_call({:rollback_transaction, client}, _from, state) do
    if client_has_transaction?(client, state.transactions) do
      transactions = Map.delete(state.transactions, client)
      {:reply, :ok, %{state | transactions: transactions}}
    else
      {:reply, {:error, :no_active_transaction}, state}
    end
  end

  def handle_call({:commit_transaction, client}, _from, state) do
    if client_has_transaction?(client, state.transactions) do
      case TransactionManager.commit(client, state.transactions) do
        {:ok, transactions} ->
          {:reply, :ok, %{state | transactions: transactions}}

        {:error, transactions, conflict_keys} ->
          {:reply, {:error, conflict_keys}, %{state | transactions: transactions}}
      end
    else
      {:reply, {:error, :no_active_transaction}, state}
    end
  end

  defp client_has_transaction?(client, transactions_map) do
    Map.has_key?(transactions_map, client)
  end

  defp get_key_current_value(key, reader_pid) do
    case Reader.get(reader_pid, key) do
      {:ok, value} -> value
      _error -> nil
    end
  end

  defp new_transaction(client, transactions) do
    Map.put(transactions, client, %{
      offset: Writer.get_current_offset(),
      values: %{}
    })
  end
end

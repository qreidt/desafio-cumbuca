defmodule KV.Engine.TransactionManager do
  @moduledoc """
  Realizar operações do banco de dados utilizando transações
  """

  alias KV.Engine
  alias KV.Engine.{Index, Writer}

  @spec put(binary(), binary(), Engine.input_value(), map(), fun()) :: {Engine.output_value(), map()}
  @doc """
  Atualizar o valor de uma chave na transação.
  Caso a chave não exista ainda na transação, buscar valor antigo nos registros.
  """
  def put(client, key, value, transactions, find_in_file) do
    transaction = Map.get(transactions, client)

    {old_value, updated_transaction_values} =
      Map.get_and_update(transaction.values, key, &get_and_update(&1, value, find_in_file))

    updated_transactions_map =
      Map.put(transactions, client, %{
        offset: transaction.offset,
        values: updated_transaction_values
      })

    {old_value, updated_transactions_map}
  end

  defp get_and_update(nil, value, find_in_file) do
    {find_in_file.(), value}
  end

  defp get_and_update(old_value, value, _) do
    {old_value, value}
  end

  @spec get(binary(), binary(), map(), fun()) :: Engine.output_value()
  @doc """
  Obter valor de uma chave da transação.
  Caso chave não exista na transação, verificar valor em disco.
  """
  def get(client, key, transactions, find_in_file) do
    transaction = Map.get(transactions, client)

    case Map.get(transaction.values, key) do
      nil -> find_in_file.()
      value -> value
    end
  end

  @spec commit(binary(), map()) :: {:ok, map()} | {:error, map(), [binary()]}
  @doc """
  Validar chaves da transação e salvar em disco caso esteja tudo correto.
  Falhar caso exista uma chave em disco mais nova do que o offset inicial da transação.
  """
  def commit(client, transactions) do
    %{offset: offset, values: transaction_values} = Map.get(transactions, client)
    result_transactions = Map.delete(transactions, client)

    case transaction_can_be_commited?(offset, transaction_values) do
      :ok ->
        commit_transaction(transaction_values)
        {:ok, result_transactions}

      {:error, conflict_keys} ->
        {:error, result_transactions, conflict_keys}
    end
  end

  defp transaction_can_be_commited?(offset, map) do
    conflict_keys = Enum.reduce(map, [], fn {k, _}, agg ->
      if newer_key_exists?(offset, k) do
        [k | agg]
      else
        agg
      end
    end)

    if conflict_keys == [] do
      :ok
    else
      {:error, conflict_keys}
    end
  end

  defp newer_key_exists?(offset, key) do
    case Index.lookup(key) do
      {:ok, {value_offset, _}} -> offset <= value_offset
      {:error, :not_found} -> false
    end
  end

  defp commit_transaction(values_map) do
    Enum.each(values_map, fn {k, v} -> Writer.put(k, v) end)
  end
end

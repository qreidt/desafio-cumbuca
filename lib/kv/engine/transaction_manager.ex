defmodule KV.Engine.TransactionManager do
  @moduledoc """
  Realizar operações do banco de dados utilizando transações
  """

  alias KV.Engine

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
end

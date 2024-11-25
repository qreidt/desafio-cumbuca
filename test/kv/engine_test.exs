defmodule KV.EngineTest do
  use ExUnit.Case, async: true

  alias KV.Engine
  alias KV.DatabaseEngineHelper

  describe "get/2" do
    test "reads strings from database file" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, "teste123")

      assert Engine.get(client, key) == "teste123"
    end

    test "reads integers from database file" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 123)

      assert Engine.get(client, key) == 123
    end

    test "reads booleans from database file" do
      client = DatabaseEngineHelper.get_random_string()
      key_1 = DatabaseEngineHelper.get_random_string()
      key_2 = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key_1, true)
      Engine.put(client, key_2, false)

      assert Engine.get(client, key_1) == true
      assert Engine.get(client, key_2) == false
    end
  end

  describe "put/3" do
    test "puts strings into the database file" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()


      assert Engine.put(client, key, "teste123") == {nil, "teste123"}
      assert Engine.put(client, key, "teste456") == {"teste123", "teste456"}
    end

    test "puts integers into the database file" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()


      assert Engine.put(client, key, 123) == {nil, 123}
      assert Engine.put(client, key, 456) == {123, 456}
    end

    test "puts booleans into the database file" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()


      assert Engine.put(client, key, true) == {nil, true}
      assert Engine.put(client, key, 456) == {true, 456}
    end
  end

  describe "begin_transaction/1" do
    test "stars a new map for the client" do
      client = DatabaseEngineHelper.get_random_string()
      Engine.begin_transaction(client)

      %{transactions: transactions} = :sys.get_state(GenServer.whereis(Engine))
      assert Map.has_key?(transactions, client)
    end

    test "transaction puts data in-memory only" do
      client = DatabaseEngineHelper.get_random_string()
      key_1 = DatabaseEngineHelper.get_random_string()
      key_2 = DatabaseEngineHelper.get_random_string()

      # offset = 8 bytes + key length = uint16 + uint32 + key + uint8
      Engine.put(client, key_1, 123)
      Engine.put(client, key_2, 456)

      Engine.begin_transaction(client)

      {old_value, new_value} = Engine.put(client, key_2, 789)

      assert old_value == 456
      assert new_value == 789

      %{transactions: %{^client => %{
        values: %{^key_2 => transaction_value}}
      }} = :sys.get_state(GenServer.whereis(Engine))

      assert transaction_value == 789
    end

    test "other clients can't see values in the transaction" do
      client_1 = DatabaseEngineHelper.get_random_string()
      client_2 = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()


      # offset = 8 bytes + key length = uint16 + uint32 + key + uint8
      Engine.put(client_1, key, 123)
      Engine.begin_transaction(client_1)
      Engine.put(client_1, key, 456)

      assert Engine.get(client_1, key) == 456
      assert Engine.get(client_2, key) == 123
    end

    test "fails if a transaction already exists" do
      client = DatabaseEngineHelper.get_random_string()

      Engine.begin_transaction(client)
      assert Engine.begin_transaction(client) == {:error, :active_transaction}
    end
  end

  describe "rollback_transaction/1" do
    test "deletes the map for the client" do
      client = DatabaseEngineHelper.get_random_string()

      Engine.begin_transaction(client)
      Engine.rollback_transaction(client)

      %{transactions: transactions} = :sys.get_state(GenServer.whereis(Engine))
      assert Map.has_key?(transactions, client) == false
    end

    test "it does't affect information outside the transaction" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, true)
      Engine.begin_transaction(client)
      Engine.put(client, key, false)

      Engine.rollback_transaction(client)
      assert Engine.put(client, key, 123) == {true, 123}
    end

    test "fails if a transaction doesn't exist" do
      client = DatabaseEngineHelper.get_random_string()
      assert Engine.rollback_transaction(client) == {:error, :no_active_transaction}
    end
  end

  describe "commit_transaction/1" do
    test "commits changes transaction to disk" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 12)
      Engine.begin_transaction(client)
      Engine.put(client, key, 345)
      Engine.put(client, key, 678)

      assert Engine.get("client-B", key) == 12

      Engine.commit_transaction(client)
      assert Engine.get("client-B", key) == 678
    end

    test "fails if a there is a conflict with a key newer than the transaction" do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 12)
      Engine.begin_transaction(client)
      Engine.put(client, key, 345)
      Engine.put("client-B", key, 678)

      assert Engine.commit_transaction(client) == :error
    end
  end
end

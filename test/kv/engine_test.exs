defmodule KV.EngineTest do
  use ExUnit.Case, async: true

  alias KV.Engine

  # Criar arquivos com nomes aleatórios para isolar testes
  defp random_test_file do
    path =
      "tmp/test"
      |> String.split("/")
      |> Enum.reduce("",
        fn dir, agg_path ->
          current_dir = agg_path <> "#{dir}/"

          if !File.exists?(current_dir) do
            File.mkdir(current_dir)
          end

          current_dir
        end)

    rand = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdefghijklmnopqrstuvwxyz")>>
    path <> "#{rand}.db"
  end

  describe "get/2" do
    test "reads strings from database file" do
      Engine.start_link(random_test_file())
      Engine.put("client", "teste", "teste123")

      assert Engine.get("client", "teste") == "teste123"
    end

    test "reads integers from database file" do
      Engine.start_link(random_test_file())
      Engine.put("client", "_int", 123)

      assert Engine.get("client", "_int") == 123
    end

    test "reads booleans from database file" do
      Engine.start_link(random_test_file())
      Engine.put("client", "_true", true)
      Engine.put("client", "_false", false)

      assert Engine.get("client", "_true") == true
      assert Engine.get("client", "_false") == false
    end
  end

  describe "put/3" do
    test "puts strings into the database file" do
      Engine.start_link(random_test_file())

      assert Engine.put("client", "teste", "teste123") == {nil, "teste123"}
      assert Engine.put("client", "teste", "teste456") == {"teste123", "teste456"}
    end

    test "puts integers into the database file" do
      Engine.start_link(random_test_file())

      assert Engine.put("client", "_int", 123) == {nil, 123}
      assert Engine.put("client", "_int", 456) == {123, 456}
    end

    test "puts booleans into the database file" do
      Engine.start_link(random_test_file())

      assert Engine.put("client", "_bool", true) == {nil, true}
      assert Engine.put("client", "_bool", 456) == {true, 456}
    end
  end

  describe "begin_transaction/1" do
    test "stars a new map for the client" do
      {:ok, pid} = Engine.start_link(random_test_file())
      Engine.begin_transaction("client")

      %{transactions: transactions} = :sys.get_state(pid)
      assert Map.has_key?(transactions, "client")
    end

    test "gets the current file offset" do
      {:ok, pid} = Engine.start_link(random_test_file())

      # offset = 8 bytes + key length = uint16 + uint32 + key + uint8
      Engine.put("client", "_", true)
      Engine.put("client", "_", true)

      Engine.begin_transaction("client")

      %{transactions: %{"client" => %{offset: offset}}} = :sys.get_state(pid)
      assert offset == 18
    end

    test "transaction puts data in-memory only" do
      {:ok, pid} = Engine.start_link(random_test_file())

      # offset = 8 bytes + key length = uint16 + uint32 + key + uint8
      Engine.put("client", "key_1", 123)
      Engine.put("client", "key_2", 456)

      Engine.begin_transaction("client")

      {old_value, new_value} = Engine.put("client", "key_2", 789)

      assert old_value == 456
      assert new_value == 789

      %{transactions: %{"client" => %{
        values: %{"key_2" => transaction_value}}
      }} = :sys.get_state(pid)

      assert transaction_value == 789
    end

    test "other clients can't see values in the transaction" do
      Engine.start_link(random_test_file())

      # offset = 8 bytes + key length = uint16 + uint32 + key + uint8
      Engine.put("client-A", "key", 123)
      Engine.begin_transaction("client-A")
      Engine.put("client-A", "key", 456)

      assert Engine.get("client-A", "key") == 456
      assert Engine.get("client-B", "key") == 123
    end

    test "fails if a transaction already exists" do
      Engine.start_link(random_test_file())

      Engine.begin_transaction("client")
      assert Engine.begin_transaction("client") == {:error, :active_transaction}
    end
  end

  describe "rollback_transaction/1" do
    test "deletes the map for the client" do
      {:ok, pid} = Engine.start_link(random_test_file())
      Engine.begin_transaction("client")
      Engine.rollback_transaction("client")

      %{transactions: transactions} = :sys.get_state(pid)
      assert Map.has_key?(transactions, "client") == false
    end

    test "it does't affect information outside the transaction" do
      Engine.start_link(random_test_file())

      Engine.put("client", "_", true)
      Engine.begin_transaction("client")
      Engine.put("client", "_", false)

      Engine.rollback_transaction("client")
      assert Engine.put("client", "_", 123) == {true, 123}
    end

    test "fails if a transaction doesn't exist" do
      Engine.start_link(random_test_file())

      assert Engine.rollback_transaction("client") == {:error, :no_active_transaction}
    end
  end

  describe "commit_transaction/1" do
    test "commits changes transaction to disk" do
      Engine.start_link(random_test_file())

      Engine.put("client", "key", 12)
      Engine.begin_transaction("client")
      Engine.put("client", "key", 345)
      Engine.put("client", "key", 678)

      assert Engine.get("client-B", "key") == 12

      Engine.commit_transaction("client")
      assert Engine.get("client-B", "key") == 678
    end

    test "fails if a there is a conflict with a key newer than the transaction" do
      Engine.start_link(random_test_file())

      Engine.put("client", "key", 12)
      Engine.begin_transaction("client")
      Engine.put("client", "key", 345)
      Engine.put("client-B", "key", 678)

      assert Engine.commit_transaction("client") == :error
    end
  end
end

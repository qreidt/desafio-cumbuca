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

  describe "get/1" do
    test "reads strings from database file" do
      Engine.start_link(random_test_file())
      Engine.put("teste", "teste123")

      assert Engine.get("teste") == "teste123"
    end

    test "reads integers from database file" do
      Engine.start_link(random_test_file())
      Engine.put("_int", 123)

      assert Engine.get("_int") == 123
    end

    test "reads booleans from database file" do
      Engine.start_link(random_test_file())
      Engine.put("_true", true)
      Engine.put("_false", false)

      assert Engine.get("_true") == true
      assert Engine.get("_false") == false
    end
  end

  describe "put/2" do
    test "puts strings into the database file" do
      Engine.start_link(random_test_file())

      assert Engine.put("teste", "teste123") == {nil, "teste123"}
      assert Engine.put("teste", "teste456") == {"teste123", "teste456"}
    end

    test "puts integers into the database file" do
      Engine.start_link(random_test_file())

      assert Engine.put("_int", 123) == {nil, 123}
      assert Engine.put("_int", 456) == {123, 456}
    end

    test "puts booleans into the database file" do
      Engine.start_link(random_test_file())

      assert Engine.put("_bool", true) == {nil, true}
      assert Engine.put("_bool", 456) == {true, 456}
    end
  end
end

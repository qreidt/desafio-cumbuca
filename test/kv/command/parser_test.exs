defmodule KV.Command.ParserTest do
  use ExUnit.Case, async: true

  alias KV.Command.Parser

  describe "parse_params/1" do
    test "parses single string" do
      assert Parser.parse_params("ABC") == {:ok, ["ABC"]}
      assert Parser.parse_params("\"ABC\"") == {:ok, ["ABC"]}
    end

    test "parses booleans" do
      assert Parser.parse_params("TRUE") == {:ok, [:TRUE]}
      assert Parser.parse_params("FALSE") == {:ok, [:FALSE]}
    end

    test "parses integers" do
      assert Parser.parse_params("10") == {:ok, [10]}
    end

    test "parses quoted strings with spaces" do
      assert Parser.parse_params("\"AB C\"") == {:ok, ["AB C"]}
    end

    test "handles unclosed strings" do
      assert Parser.parse_params("\"AB\"C\"") == {:err, :syntax_error}
    end

    test "handles mixed inputs" do
      input = "ABC 10 \"AB C\" TRUE"
      assert Parser.parse_params(input) == {:ok, ["ABC", 10, "AB C", :TRUE]}
    end

    test "returns {:err, :syntax_error} for invalid quoted strings" do
      # If the quoted string check is meant to return an error for invalid cases:
      assert Parser.parse_params("unclosed\"") == {:err, :syntax_error}
      assert Parser.parse_params("\"unclosed") == {:err, :syntax_error}
      assert Parser.parse_params("unclosed\\") == {:err, :syntax_error}
    end

    test "handles real scenarios" do
      assert Parser.parse_params("teste 1") == {:ok, ["teste", 1]}
      assert Parser.parse_params("\"chave composta\" 1") == {:ok, ["chave composta", 1]}
      assert Parser.parse_params("\"chave composta com \\\"aspas\\\"\" 1") == {:ok, ["chave composta com \"aspas\"", 1]}
    end
  end

  describe "parse_token/1" do
    test "parses boolean tokens" do
      assert Parser.parse_token("TRUE") == {:ok, :TRUE}
      assert Parser.parse_token("FALSE") == {:ok, :FALSE}
      assert Parser.parse_token("\"TRUE\"") == {:ok, "TRUE"}
      assert Parser.parse_token("\"FALSE\"") == {:ok, "FALSE"}
    end

    test "parses integer tokens" do
      assert Parser.parse_token("123") == {:ok, 123}
      assert Parser.parse_token("0") == {:ok, 0}
      assert Parser.parse_token("0.0") == {:ok, "0.0"}
    end

    test "parses NIL token" do
      assert Parser.parse_token("NIL") == {:ok, nil}
      assert Parser.parse_token("\"NIL\"") == {:ok, "NIL"}
    end

    test "parses quoted string tokens" do
      assert Parser.parse_token("\"hello\"") == {:ok, "hello"}
      assert Parser.parse_token("\"quoted string\"") == {:ok, "quoted string"}
      assert Parser.parse_token("\"quoted\"string\"") == {:ok, "quoted\"string"}
    end

    test "handles generic string tokens" do
      assert Parser.parse_token("generic_token") == {:ok, "generic_token"}
      assert Parser.parse_token("hello_world123") == {:ok, "hello_world123"}
    end
  end
end

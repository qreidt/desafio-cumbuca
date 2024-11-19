defmodule KV.CommandParserTest do
  use ExUnit.Case

  test "returns a string" do
    assert KV.CommandParser.parse_params("") == {:ok, []}
  end
end

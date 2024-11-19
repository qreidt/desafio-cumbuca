defmodule KV.TokenizerTest do
  use ExUnit.Case, async: true

  alias KV.Tokenizer

  describe "tokenize/1" do
    test "splits tokens separated by spaces" do
      assert Tokenizer.tokenize("key1 key2 key3") == ["key1", "key2", "key3"]
    end

    test "handles quoted tokens with spaces inside" do
      assert Tokenizer.tokenize(~s("key with spaces" another_key)) == ["\"key with spaces\"", "another_key"]
      assert Tokenizer.tokenize(~s("multi word token")) == ["\"multi word token\""]
    end

    test "handles escaped quotes inside quoted tokens" do
      assert Tokenizer.tokenize("\"key with \\\"escaped quotes\\\"\"") == ["\"key with \"escaped quotes\"\""]
      assert Tokenizer.tokenize(~s(\"hello \\\"world\\\"\" remaining)) == ["\"hello \"world\"\"", "remaining"]
    end

    test "handles backslashes inside quoted tokens" do
      assert Tokenizer.tokenize(~s("path\\\\to\\\\file")) == ["\"path\\to\\file\""]
    end

    test "handles empty input" do
      assert Tokenizer.tokenize("") == []
    end

    test "ignores leading and trailing spaces" do
      assert Tokenizer.tokenize("   key1 key2   ") == ["key1", "key2"]
    end

    test "handles unquoted tokens without spaces" do
      assert Tokenizer.tokenize("simple_token") == ["simple_token"]
    end

    test "handles unquoted tokens with mixed valid cases" do
      assert Tokenizer.tokenize(~s("quoted token" unquoted_token "another quoted")) == ["\"quoted token\"", "unquoted_token", "\"another quoted\""]
    end

    test "returns :err for unclosed quotes" do
      assert Tokenizer.tokenize(~s("unclosed_token)) == :err
      assert Tokenizer.tokenize(~s(key1 "unclosed_token)) == :err
    end

    test "returns :err for dangling backslash" do
      assert Tokenizer.tokenize("key1 \\") == :err
      assert Tokenizer.tokenize(~s("key with \\)) == :err
    end

    test "handles consecutive spaces correctly" do
      assert Tokenizer.tokenize("key1    key2 key3") == ["key1", "key2", "key3"]
    end

    test "handles only spaces" do
      assert Tokenizer.tokenize("   ") == []
    end
  end
end

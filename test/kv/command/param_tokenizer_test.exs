defmodule KV.Command.ParamTokenizerTest do
  use ExUnit.Case, async: true

  alias KV.Command.ParamTokenizer

  describe "tokenize/1" do
    test "splits tokens separated by spaces" do
      assert ParamTokenizer.tokenize("key1 key2 key3") == ["key1", "key2", "key3"]
    end

    test "handles quoted tokens with spaces inside" do
      assert ParamTokenizer.tokenize(~s("key with spaces" another_key)) == ["\"key with spaces\"", "another_key"]
      assert ParamTokenizer.tokenize(~s("multi word token")) == ["\"multi word token\""]
    end

    test "handles escaped quotes inside quoted tokens" do
      assert ParamTokenizer.tokenize("\"key with \\\"escaped quotes\\\"\"") == ["\"key with \"escaped quotes\"\""]
      assert ParamTokenizer.tokenize(~s(\"hello \\\"world\\\"\" remaining)) == ["\"hello \"world\"\"", "remaining"]
    end

    test "handles backslashes inside quoted tokens" do
      assert ParamTokenizer.tokenize(~s("path\\\\to\\\\file")) == ["\"path\\to\\file\""]
    end

    test "handles empty input" do
      assert ParamTokenizer.tokenize("") == []
    end

    test "ignores leading and trailing spaces" do
      assert ParamTokenizer.tokenize("   key1 key2   ") == ["key1", "key2"]
    end

    test "handles unquoted tokens without spaces" do
      assert ParamTokenizer.tokenize("simple_token") == ["simple_token"]
    end

    test "handles unquoted tokens with mixed valid cases" do
      assert ParamTokenizer.tokenize(~s("quoted token" unquoted_token "another quoted")) == ["\"quoted token\"", "unquoted_token", "\"another quoted\""]
    end

    test "returns :err for unclosed quotes" do
      assert ParamTokenizer.tokenize(~s("unclosed_token)) == :err
      assert ParamTokenizer.tokenize(~s(key1 "unclosed_token)) == :err
    end

    test "returns :err for dangling backslash" do
      assert ParamTokenizer.tokenize("key1 \\") == :err
      assert ParamTokenizer.tokenize(~s("key with \\)) == :err
    end

    test "handles consecutive spaces correctly" do
      assert ParamTokenizer.tokenize("key1    key2 key3") == ["key1", "key2", "key3"]
    end

    test "handles only spaces" do
      assert ParamTokenizer.tokenize("   ") == []
    end
  end
end

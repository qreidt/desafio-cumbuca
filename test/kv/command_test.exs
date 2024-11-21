defmodule KV.CommandTest do
  use ExUnit.Case, async: true

  alias KV.Command

  describe "validate_command/2" do
    test "validates GET command params" do
      syntax_error_msg = Command.get_syntax_error_msg()
      assert Command.validate_command(:GET, ["teste"]) == :ok
      assert Command.validate_command(:GET, ["\"teste\""]) == :ok
      assert Command.validate_command(:GET, ["teste 123"]) == :ok
      assert Command.validate_command(:GET, [123]) == {:err, syntax_error_msg}
      assert Command.validate_command(:GET, ["123"]) == :ok
      assert Command.validate_command(:GET, [nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:GET, ["teste", "teste"]) == {:err, syntax_error_msg}
    end

    test "validates SET command params" do
      syntax_error_msg = Command.set_syntax_error_msg()
      assert Command.validate_command(:SET, ["teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:SET, ["teste", "teste"]) == :ok
      assert Command.validate_command(:SET, ["teste 123", 123]) == :ok
      assert Command.validate_command(:SET, [123, "teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:SET, [nil, nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:SET, ["teste", "teste", "teste"]) == {:err, syntax_error_msg}
    end

    test "validates BEGIN command params" do
      syntax_error_msg = Command.begin_syntax_error_msg()
      assert Command.validate_command(:BEGIN, []) == :ok
      assert Command.validate_command(:BEGIN, ["teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:BEGIN, ["123", "teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:BEGIN, [123]) == {:err, syntax_error_msg}
      assert Command.validate_command(:BEGIN, [nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:BEGIN, ["123", nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:BEGIN, [nil, nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:BEGIN, ["teste", "teste", "teste"]) == {:err, syntax_error_msg}
    end

    test "validates ROLLBACK command params" do
      syntax_error_msg = Command.rollback_syntax_error_msg()
      assert Command.validate_command(:ROLLBACK, []) == :ok
      assert Command.validate_command(:ROLLBACK, ["teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:ROLLBACK, ["123", "teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:ROLLBACK, [123]) == {:err, syntax_error_msg}
      assert Command.validate_command(:ROLLBACK, [nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:ROLLBACK, ["123", nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:ROLLBACK, [nil, nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:ROLLBACK, ["teste", "teste", "teste"]) == {:err, syntax_error_msg}
    end

    test "validates COMMIT command params" do
      syntax_error_msg = Command.commit_syntax_error_msg()
      assert Command.validate_command(:COMMIT, []) == :ok
      assert Command.validate_command(:COMMIT, ["teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:COMMIT, ["123", "teste"]) == {:err, syntax_error_msg}
      assert Command.validate_command(:COMMIT, [123]) == {:err, syntax_error_msg}
      assert Command.validate_command(:COMMIT, [nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:COMMIT, ["123", nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:COMMIT, [nil, nil]) == {:err, syntax_error_msg}
      assert Command.validate_command(:COMMIT, ["teste", "teste", "teste"]) == {:err, syntax_error_msg}
    end
  end
end

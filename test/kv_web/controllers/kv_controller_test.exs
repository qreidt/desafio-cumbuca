defmodule KVWeb.Controllers.KvControllerTest do
  use KVWeb.ConnCase, async: true

  alias KV.DatabaseEngineHelper
  alias KV.Engine
  alias KV.Command

  defp send_request(conn, client, command) do
    %Plug.Conn{resp_body: resp_body} = put_req_header(conn, "x-client-name", client)
      |> put_req_header("content-type", "application/text")
      |> post("", command)

    resp_body
  end

  describe "wrong commands" do
    test "fails if a unkown command is sent", %{conn: conn} do
      assert send_request(conn, "client", "TRY") == "ERR \"No command TRY\""
    end
  end

  describe "GET command" do
    test "gets a value value from the database or nil", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      assert send_request(conn, client, "GET #{key}") == "1"
      assert send_request(conn, client, "GET teste2") == "NIL"
    end

    test "should accept exactly 1 parameter", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      assert send_request(conn, client, "GET param1 param2 param3") == Command.get_syntax_error_msg()
      assert send_request(conn, client, "GET") == Command.get_syntax_error_msg()
      assert send_request(conn, client, "GET #{key}") == "NIL"
    end
  end

  describe "SET command" do
    test "inserts a value into the database and also returns the last one for that key", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      assert send_request(conn, client, "SET #{key} 1") == "1 1"
      assert send_request(conn, client, "SET #{key} 2") == "1 2"
      assert Engine.get(client, key) == 2
    end

    test "should accept exactly 2 parameters", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      assert send_request(conn, client, "SET param1 param2 param3") == Command.set_syntax_error_msg()
      assert send_request(conn, client, "SET #{key}") == Command.set_syntax_error_msg()
      assert send_request(conn, client, "SET #{key} 1") == "NIL 1"
    end
  end

  describe "BEGIN command" do
    test "starts a new transaction", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      Engine.put(client, key, 2)
      assert send_request(conn, client, "BEGIN") == "OK"
      assert send_request(conn, client, "SET #{key} 3") == "2 3"
      assert send_request(conn, "client-B", "GET #{key}") == "2"
    end
  end

  describe "ROLLBACK command" do
    test "rollback an existing transaction", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      Engine.put(client, key, 2)
      assert send_request(conn, client, "BEGIN") == "OK"
      assert send_request(conn, client, "SET #{key} 3") == "2 3"
      assert send_request(conn, "client-B", "GET #{key}") == "2"
      assert send_request(conn, client, "ROLLBACK") == "OK"
      assert send_request(conn, client, "GET #{key}") == "2"
      assert send_request(conn, "client-B", "GET #{key}") == "2"
    end

    test "ROLLBACK fails if the transaction doesn't exist", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      Engine.put(client, key, 2)
      assert send_request(conn, client, "COMMIT") == "ERR \"No active transaction\""
    end
  end

  describe "COMMIT command" do
    test "commits an existing transaction", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      Engine.put(client, key, 2)
      assert send_request(conn, client, "BEGIN") == "OK"
      assert send_request(conn, client, "SET #{key} 3") == "2 3"
      assert send_request(conn, "client-B", "GET #{key}") == "2"
      assert send_request(conn, client, "COMMIT") == "OK"
      assert send_request(conn, client, "GET #{key}") == "3"
      assert send_request(conn, "client-B", "GET #{key}") == "3"
    end

    test "COMMIT fails if the transaction doesn't exist", %{conn: conn} do
      client = DatabaseEngineHelper.get_random_string()
      key = DatabaseEngineHelper.get_random_string()

      Engine.put(client, key, 1)
      Engine.put(client, key, 2)
      assert send_request(conn, client, "COMMIT") == "ERR \"No active transaction\""
    end
  end
end

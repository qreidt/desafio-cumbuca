defmodule KVWeb.Controllers.KvController do
  use KVWeb, :controller

  @doc """
  Função principal para receber requisições de KVs
  """
  def handle(conn, _) do
    client = conn.assigns.x_client_name

    with {:ok, body, _} <- Plug.Conn.read_body(conn),
      {:ok, response} <- KV.Command.execute(client, body) do
        text(conn, response)

    else
      {:err, reason} ->
        put_status(conn, 400)
        |> text(reason)

      _ ->
        put_status(conn, 500)
        |> text("Server Error")
    end
  end
end

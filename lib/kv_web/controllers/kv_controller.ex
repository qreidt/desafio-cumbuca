defmodule KVWeb.Controllers.KvController do
  use KVWeb, :controller

  @doc """
  Função principal para receber requisições de KVs
  """
  def handle(conn, _params) do
    text(conn, "OK")
  end
end
defmodule KVWeb.Router do
  use KVWeb, :router

  # Middleware para identificar presença do header
  pipeline :main do
    plug KVWeb.Plugs.ClientPlug
  end

  scope "/", KVWeb.Controllers do
    pipe_through :main
    post "/", KvController, :handle
  end
end

defmodule KVWeb.Router do
  use KVWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KVWeb do
    pipe_through :api
  end
end

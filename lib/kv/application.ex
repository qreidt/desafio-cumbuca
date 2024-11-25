defmodule KV.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KVWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:kv, :dns_cluster_query) || :ignore},
      # {Phoenix.PubSub, name: KV.PubSub},
      # Start a worker by calling: KV.Worker.start_link(arg)
      # {KV.Worker, arg},
      # Start to serve requests, typically the last entry

      KV.Engine,
      KVWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KV.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KVWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

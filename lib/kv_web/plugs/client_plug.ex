defmodule KVWeb.Plugs.ClientPlug do
  import Plug.Conn

  @doc """
  Initialize the plug with options.
  """
  def init(opts), do: opts

  @doc """
  Call function to check for the required header.
  """
  def call(conn, _opts) do
    # Realizar um join para verificar se o header realmente está vazio
    x_client_name = Enum.join(get_req_header(conn, "x-client-name"))

    # Falhar a requisição caso o header não contenha informações
    if x_client_name == "" do

      send_resp(conn, :bad_request, "X-Client-Name header not present")
        |> halt() # Parar processamento da requisição
    else

      # Header presente. Fornecer resultado para controller
      assign(conn, :x_client_name, x_client_name)
    end
  end

end

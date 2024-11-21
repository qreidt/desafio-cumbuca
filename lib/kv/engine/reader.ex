defmodule KV.Engine.Reader do
  use GenServer

  alias KV.Engine.Index

  # Iniciar GenServer com caminho para arquivo de log
  def start_link(log_path) do
    GenServer.start_link(__MODULE__, log_path)
  end

  # Criar e/ou abrir arquivo no local dado
  def init(log_path) do
    fd = File.open!(log_path, [:read, :binary])
    {:ok, %{fd: fd}}
  end

  # Ler o valor pertencente a chave informada
  @spec get(pid(), binary()) :: {:ok, binary()|integer()|boolean()} | {:error, any()}
  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  # Buscar valor offset e tamanho da chave no índice
  # Retornar dados lidos do arquivo ou retornar erro
  def handle_call({:get, key}, _from, %{fd: fd} = state) do
    case Index.lookup(key) do
      {:ok, {offset, size}} ->
        {:reply, :file.pread(fd, offset, size), state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end
end

defmodule KV.Engine.Reader do
  use GenServer

  alias KV.Engine.{Index}

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
        response = read_registered_item(fd, offset, size)
        {:reply, response, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  defp read_registered_item(fd, offset, value_size) do
    with {:ok, raw_data} <- :file.pread(fd, offset, value_size) do
      <<type::integer-8, value_data::bitstring-size((value_size-1) * 8)>> = raw_data
      read_binary_type(type, value_data)
    end
  end

  defp read_binary_type(1, value_data)  do
    {:ok, << value_data::binary >>}
  end

  defp read_binary_type(2, value_data) do
    {:ok, :binary.decode_unsigned(value_data)}
  end

  defp read_binary_type(3, value_data)  do
    {:ok, :binary.decode_unsigned(value_data) == 1}
  end

  defp read_binary_type(_, _)  do
    {:error, :no_type}
  end
end

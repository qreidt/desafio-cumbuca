defmodule KV.DatabaseEngineHelper do

  # Criar arquivos com nomes aleatórios para isolar testes
  def random_test_file do
    path =
      "tmp/test"
      |> String.split("/")
      |> Enum.reduce("",
        fn dir, agg_path ->
          current_dir = agg_path <> "#{dir}/"

          if !File.exists?(current_dir) do
            File.mkdir(current_dir)
          end

          current_dir
        end)

    path <> "#{get_random_string()}.db"
  end

  def get_random_string do
    for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdefghijklmnopqrstuvwxyz")>>
  end
end

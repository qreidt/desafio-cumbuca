import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kv, KVWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "pM5hRXE4LlTBhbH+oJTy6B+g8x/6pK0Yfcxl68ILh8kNKndaE+hk6pZiyGOnqTaZ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

test_path = "tmp/test"
  |> String.split("/")
  |> Enum.reduce("",
    fn dir, agg_path ->
      current_dir = agg_path <> "#{dir}/"

      if !File.exists?(current_dir) do
        File.mkdir(current_dir)
      end

      current_dir
    end)

rand = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdefghijklmnopqrstuvwxyz")>>

config :phoenix, :log_path, (test_path <> "#{rand}.db")

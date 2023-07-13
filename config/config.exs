import Config

ci? = System.get_env("CI", "") != ""

config :stream_data,
  max_runs: if(ci?, do: 10_000, else: 100)

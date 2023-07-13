import Config

ci? = System.get_env("CI", "") != ""

config :stream_data,
  max_runs: if(ci?, do: 500, else: 100)

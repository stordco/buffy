# Buffy

Buffy is a small library of Elixir modules to assist in throttling and debouncing function calling.

## Roadmap

- [ ] Allow limiting concurrency of running tasks
- [ ] Create a debounce module
- [X] Telemetry instrumentation

## Installation

Just add [`buffy`](https://hex.pm/packages/buffy) to your `mix.exs` file like so:

<!-- {x-release-please-start-version} -->
```elixir
def deps do
  [
    {:buffy, "~> 2.3.1"}
  ]
end
```
<!-- {x-release-please-end} -->

## Published Documentation

Documentation is automatically generated and published to [HexDocs](https://hexdocs.pm/buffy/readme.html) on new releases.

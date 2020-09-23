# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :battleline,
  ecto_repos: [Battleline.Repo]

# Configures the endpoint
config :battleline, BattlelineWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "boFPcazjxmzg6vb0m7SiXKMo3/fA211i2GFvB/ZyLsL1LvjABQ6sp16MUSXWTqxw",
  render_errors: [view: BattlelineWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Battleline.PubSub,
  live_view: [signing_salt: "6dnhL2Nd"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

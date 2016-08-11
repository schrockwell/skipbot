# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :skipbot,
  ecto_repos: [Skipbot.Repo]

# Configures the endpoint
config :skipbot, Skipbot.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "B+7jH8NmhV4mW7egGTpmz8YoCBWf04YT+uvDCTReGVcWgpzpcjR2PVqk+v8dmYT5",
  render_errors: [view: Skipbot.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Skipbot.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

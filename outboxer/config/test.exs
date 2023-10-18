import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :outboxer, OutboxerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yptkUAueVmaAwPInwpc/wv6et3XmyJyn9GL+SptYvQDf9+NaqDwKywypm9tY5WtV",
  server: false

# In test we don't send emails.
config :outboxer, Outboxer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

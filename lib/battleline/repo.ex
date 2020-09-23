defmodule Battleline.Repo do
  use Ecto.Repo,
    otp_app: :battleline,
    adapter: Ecto.Adapters.Postgres
end

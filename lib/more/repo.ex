defmodule More.Repo do
  use Ecto.Repo,
    otp_app: :more,
    adapter: Ecto.Adapters.Postgres
end

defmodule MoreWeb.PageController do
  use MoreWeb, :controller

  def home(conn, _params) do
    # This will be our Svelte islands playground
    render(conn, :home)
  end
end

defmodule MoreWeb.PageController do
  use MoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

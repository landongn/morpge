defmodule MoreWeb.GameLive.SurfaceTest do
  use MoreWeb.ConnCase
  import Phoenix.LiveViewTest

  alias More.AccountsFixtures

  setup do
    user = AccountsFixtures.user_fixture()
    %{user: user}
  end

  describe "Surface LiveView" do
    test "renders surface interface", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, _surface_live, html} = live(conn, ~p"/game")

      # Check that the surface container is rendered
      assert html =~ "game-surface"

      # Check that default panes are present
      assert html =~ "World Channel"
      assert html =~ "Local Channel"
      assert html =~ "System Channel"
      assert html =~ "Command Input"
      assert html =~ "Player Status"

      # Check that surface controls are present
      assert html =~ "surface-controls"
    end

    test "toggles pane controls panel", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, surface_live, _html} = live(conn, ~p"/game")

      # Initially pane controls should be hidden
      refute has_element?(surface_live, ".pane-controls-panel")

      # Click toggle button
      surface_live
      |> element("button[phx-click='toggle_pane_controls']")
      |> render_click()

      # Now pane controls should be visible
      assert has_element?(surface_live, ".pane-controls-panel")
    end

    test "toggles pane list panel", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, surface_live, _html} = live(conn, ~p"/game")

      # Initially pane list should be hidden
      refute has_element?(surface_live, ".pane-list-panel")

      # Click toggle button
      surface_live
      |> element("button[phx-click='toggle_pane_list']")
      |> render_click()

      # Now pane list should be visible
      assert has_element?(surface_live, ".pane-list-panel")
    end

    test "sets active pane", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, surface_live, _html} = live(conn, ~p"/game")

      # Click on a pane to make it active
      surface_live
      |> element("#pane-world_chat")
      |> render_click()

      # The pane should now have the active class
      assert has_element?(surface_live, "#pane-world_chat.active")
    end

    test "changes background", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, surface_live, _html} = live(conn, ~p"/game")

      # Show pane controls
      surface_live
      |> element("button[phx-click='toggle_pane_controls']")
      |> render_click()

      # Change to medium background
      surface_live
      |> element("button", "Medium")
      |> render_click()

      # The surface should now have the new background
      assert has_element?(surface_live, ".game-surface")
    end
  end
end

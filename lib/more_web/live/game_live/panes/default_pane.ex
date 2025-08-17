defmodule MoreWeb.GameLive.Panes.DefaultPane do
  use MoreWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, content: "Default Pane Content")}
  end

  @impl true
  def update(%{id: id} = assigns, socket) do
    {:ok, assign(socket, id: id, content: assigns[:content] || socket.assigns.content)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="default-pane" id={"default-pane-#{@id}"}>
      <div class="default-content">
        <p>{@content}</p>
        <p>This pane is not yet fully implemented.</p>
      </div>
    </div>
    """
  end
end

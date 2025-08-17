defmodule More.Mud.World.WorldLayer do
  @moduledoc """
  Schema representing a world layer in the game world.

  Each layer represents a different aspect of the world:
  - Ground: Foundation terrain
  - Atmosphere: Environmental effects
  - Plants: Vegetation and resources
  - Structures: Buildings and architecture
  - Floor_plans: Interior layouts
  - Doors: Passageways and connections
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "world_layers" do
    field :name, :string
    field :display_name, :string
    field :description, :string
    field :layer_order, :integer
    field :is_active, :boolean, default: true
    field :tick_interval, :integer, default: 3000
    field :metadata, :map, default: %{}

    has_many :maps, More.Mud.World.LayerMap, foreign_key: :layer_id
    has_many :entities, More.Mud.World.LayerEntity, foreign_key: :layer_id
    has_many :source_connections, More.Mud.World.LayerConnection, foreign_key: :source_layer_id
    has_many :target_connections, More.Mud.World.LayerConnection, foreign_key: :target_layer_id

    timestamps()
  end

  @doc """
  Changeset for creating or updating a world layer.
  """
  def changeset(world_layer, attrs) do
    world_layer
    |> cast(attrs, [
      :name,
      :display_name,
      :description,
      :layer_order,
      :is_active,
      :tick_interval,
      :metadata
    ])
    |> validate_required([:name, :display_name, :layer_order])
    |> validate_number(:layer_order, greater_than: 0)
    |> validate_number(:tick_interval, greater_than: 0)
    |> validate_inclusion(:name, [
      "ground",
      "atmosphere",
      "plants",
      "structures",
      "floor_plans",
      "doors"
    ])
    |> unique_constraint(:name)
    |> unique_constraint(:layer_order)
  end

  @doc """
  Gets all active layers ordered by layer_order.
  """
  def active_layers do
    from(l in __MODULE__,
      where: l.is_active == true,
      order_by: l.layer_order,
      preload: [:maps, :entities, :source_connections, :target_connections]
    )
  end

  @doc """
  Gets a layer by name.
  """
  def by_name(name) do
    from(l in __MODULE__,
      where: l.name == ^name and l.is_active == true,
      preload: [:maps, :entities, :source_connections, :target_connections]
    )
  end

  @doc """
  Gets layers for a specific zone.
  """
  def for_zone(zone_name) do
    from(l in __MODULE__,
      join: m in assoc(l, :maps),
      where: l.is_active == true and m.zone_name == ^zone_name,
      order_by: l.layer_order,
      preload: [:entities, :source_connections, :target_connections, maps: m]
    )
  end
end

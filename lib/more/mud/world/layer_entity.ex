defmodule More.Mud.World.LayerEntity do
  @moduledoc """
  Schema representing a dynamic entity within a specific layer.

  These entities can move, change, or be created/destroyed
  during gameplay, unlike the static map data.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "layer_entities" do
    field :entity_type, :string
    field :entity_id, :string
    field :x, :integer
    field :y, :integer
    field :zone_name, :string
    field :properties, :map, default: %{}
    field :is_active, :boolean, default: true

    belongs_to :layer, More.Mud.World.WorldLayer

    timestamps()
  end

  @doc """
  Changeset for creating or updating a layer entity.
  """
  def changeset(layer_entity, attrs) do
    layer_entity
    |> cast(attrs, [
      :layer_id,
      :entity_type,
      :entity_id,
      :x,
      :y,
      :zone_name,
      :properties,
      :is_active
    ])
    |> validate_required([:layer_id, :entity_type, :entity_id, :x, :y, :zone_name])
    |> validate_number(:x, greater_than_or_equal_to: 0)
    |> validate_number(:y, greater_than_or_equal_to: 0)
    |> unique_constraint([:layer_id, :entity_id])
  end

  @doc """
  Gets all entities for a specific layer and zone.
  """
  def for_layer_and_zone(layer_id, zone_name) do
    from(e in __MODULE__,
      where: e.layer_id == ^layer_id and e.zone_name == ^zone_name and e.is_active == true,
      preload: [:layer]
    )
  end

  @doc """
  Gets all entities at a specific position in a zone.
  """
  def at_position(layer_id, zone_name, x, y) do
    from(e in __MODULE__,
      where:
        e.layer_id == ^layer_id and e.zone_name == ^zone_name and e.x == ^x and e.y == ^y and
          e.is_active == true,
      preload: [:layer]
    )
  end

  @doc """
  Gets all entities of a specific type in a zone.
  """
  def of_type(layer_id, zone_name, entity_type) do
    from(e in __MODULE__,
      where:
        e.layer_id == ^layer_id and e.zone_name == ^zone_name and e.entity_type == ^entity_type and
          e.is_active == true,
      preload: [:layer]
    )
  end

  @doc """
  Gets all entities in a rectangular region.
  """
  def in_region(layer_id, zone_name, x, y, width, height) do
    from(e in __MODULE__,
      where:
        e.layer_id == ^layer_id and e.zone_name == ^zone_name and
          e.x >= ^x and e.x < ^(x + width) and
          e.y >= ^y and e.y < ^(y + height) and
          e.is_active == true,
      preload: [:layer]
    )
  end

  @doc """
  Moves an entity to a new position.
  """
  def move(entity, new_x, new_y) do
    %{entity | x: new_x, y: new_y}
  end

  @doc """
  Updates entity properties.
  """
  def update_properties(entity, new_properties) do
    updated_properties = Map.merge(entity.properties, new_properties)
    %{entity | properties: updated_properties}
  end

  @doc """
  Deactivates an entity (soft delete).
  """
  def deactivate(entity) do
    %{entity | is_active: false}
  end

  @doc """
  Activates a previously deactivated entity.
  """
  def activate(entity) do
    %{entity | is_active: true}
  end
end

defmodule More.Mud.World.LayerConnection do
  @moduledoc """
  Schema representing connections between different layers.

  These connections define how entities can move between
  layers (e.g., doors, stairs, portals).
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "layer_connections" do
    field :connection_type, :string
    field :source_x, :integer
    field :source_y, :integer
    field :target_x, :integer
    field :target_y, :integer
    field :zone_name, :string
    field :properties, :map, default: %{}

    belongs_to :source_layer, More.Mud.World.WorldLayer, foreign_key: :source_layer_id
    belongs_to :target_layer, More.Mud.World.WorldLayer, foreign_key: :target_layer_id

    timestamps()
  end

  @doc """
  Changeset for creating or updating a layer connection.
  """
  def changeset(layer_connection, attrs) do
    layer_connection
    |> cast(attrs, [
      :source_layer_id,
      :target_layer_id,
      :connection_type,
      :source_x,
      :source_y,
      :target_x,
      :target_y,
      :zone_name,
      :properties
    ])
    |> validate_required([
      :source_layer_id,
      :target_layer_id,
      :connection_type,
      :source_x,
      :source_y,
      :target_x,
      :target_y,
      :zone_name
    ])
    |> validate_number(:source_x, greater_than_or_equal_to: 0)
    |> validate_number(:source_y, greater_than_or_equal_to: 0)
    |> validate_number(:target_x, greater_than_or_equal_to: 0)
    |> validate_number(:target_y, greater_than_or_equal_to: 0)
    |> validate_inclusion(:connection_type, ["door", "stairs", "portal", "ladder", "tunnel"])
    |> unique_constraint([:source_layer_id, :source_x, :source_y])
    |> unique_constraint([:target_layer_id, :target_x, :target_y])
  end

  @doc """
  Gets all connections for a specific layer and zone.
  """
  def for_layer_and_zone(layer_id, zone_name) do
    from(c in __MODULE__,
      where:
        (c.source_layer_id == ^layer_id or c.target_layer_id == ^layer_id) and
          c.zone_name == ^zone_name,
      preload: [:source_layer, :target_layer]
    )
  end

  @doc """
  Gets all connections from a specific layer to another layer.
  """
  def between_layers(source_layer_id, target_layer_id, zone_name) do
    from(c in __MODULE__,
      where:
        c.source_layer_id == ^source_layer_id and c.target_layer_id == ^target_layer_id and
          c.zone_name == ^zone_name,
      preload: [:source_layer, :target_layer]
    )
  end

  @doc """
  Gets all connections of a specific type in a zone.
  """
  def of_type(zone_name, connection_type) do
    from(c in __MODULE__,
      where: c.zone_name == ^zone_name and c.connection_type == ^connection_type,
      preload: [:source_layer, :target_layer]
    )
  end

  @doc """
  Gets connections at a specific position in a layer.
  """
  def at_position(layer_id, zone_name, x, y) do
    from(c in __MODULE__,
      where:
        (c.source_layer_id == ^layer_id and c.source_x == ^x and c.source_y == ^y) or
          (c.target_layer_id == ^layer_id and c.target_x == ^x and c.target_y == ^y and
             c.zone_name == ^zone_name),
      preload: [:source_layer, :target_layer]
    )
  end

  @doc """
  Gets the target position for a connection from a source position.
  """
  def get_target_position(connection, source_layer_id, source_x, source_y) do
    if connection.source_layer_id == source_layer_id and
         connection.source_x == source_x and
         connection.source_y == source_y do
      {connection.target_x, connection.target_y, connection.target_layer_id}
    else
      nil
    end
  end

  @doc """
  Checks if a connection is bidirectional.
  """
  def bidirectional?(connection) do
    Map.get(connection.properties, "bidirectional", false)
  end

  @doc """
  Gets the connection cost for movement.
  """
  def get_cost(connection) do
    Map.get(connection.properties, "cost", 1)
  end

  @doc """
  Checks if a connection requires a key or special condition.
  """
  def requires_key?(connection) do
    Map.has_key?(connection.properties, "required_key")
  end

  @doc """
  Gets the required key for a connection.
  """
  def get_required_key(connection) do
    Map.get(connection.properties, "required_key")
  end
end

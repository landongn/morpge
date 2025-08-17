defmodule More.Mud.World.LayerMap do
  @moduledoc """
  Schema representing a map for a specific layer and zone.

  Each map contains ASCII data representing the visual layout
  of that layer in a specific zone.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "layer_maps" do
    field :zone_name, :string
    # ASCII map representation
    field :map_data, :string
    field :width, :integer
    field :height, :integer
    field :origin_x, :integer, default: 0
    field :origin_y, :integer, default: 0
    field :metadata, :map, default: %{}

    belongs_to :layer, More.Mud.World.WorldLayer

    timestamps()
  end

  @doc """
  Changeset for creating or updating a layer map.
  """
  def changeset(layer_map, attrs) do
    layer_map
    |> cast(attrs, [
      :layer_id,
      :zone_name,
      :map_data,
      :width,
      :height,
      :origin_x,
      :origin_y,
      :metadata
    ])
    |> validate_required([:layer_id, :zone_name, :map_data, :width, :height])
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
    |> validate_number(:origin_x, greater_than_or_equal_to: 0)
    |> validate_number(:origin_y, greater_than_or_equal_to: 0)
    |> validate_map_data()
    |> unique_constraint([:layer_id, :zone_name])
  end

  @doc """
  Gets a map for a specific layer and zone.
  """
  def for_layer_and_zone(layer_id, zone_name) do
    from(m in __MODULE__,
      where: m.layer_id == ^layer_id and m.zone_name == ^zone_name,
      preload: [:layer]
    )
  end

  @doc """
  Gets all maps for a specific zone.
  """
  def for_zone(zone_name) do
    from(m in __MODULE__,
      where: m.zone_name == ^zone_name,
      preload: [:layer]
    )
  end

  @doc """
  Gets all maps for a specific layer.
  """
  def for_layer(layer_id) do
    from(m in __MODULE__,
      where: m.layer_id == ^layer_id,
      preload: [:layer]
    )
  end

  # Validates that the map data matches the specified dimensions.
  defp validate_map_data(changeset) do
    case get_change(changeset, :map_data) do
      nil ->
        changeset

      map_data ->
        case get_change(changeset, :width) do
          nil ->
            changeset

          width ->
            case get_change(changeset, :height) do
              nil ->
                changeset

              height ->
                lines = String.split(map_data, "\n", trim: true)

                if length(lines) == height do
                  if Enum.all?(lines, &(String.length(&1) == width)) do
                    changeset
                  else
                    add_error(
                      changeset,
                      :map_data,
                      "Map data width does not match specified width"
                    )
                  end
                else
                  add_error(
                    changeset,
                    :map_data,
                    "Map data height does not match specified height"
                  )
                end
            end
        end
    end
  end

  @doc """
  Gets a character at specific coordinates in the map.
  """
  def get_at(map, x, y) do
    if x >= 0 and x < map.width and y >= 0 and y < map.height do
      lines = String.split(map.map_data, "\n", trim: true)
      line = Enum.at(lines, y)

      if line and x < String.length(line) do
        String.at(line, x)
      else
        nil
      end
    else
      nil
    end
  end

  @doc """
  Sets a character at specific coordinates in the map.
  """
  def set_at(map, x, y, char) when is_binary(char) and byte_size(char) == 1 do
    if x >= 0 and x < map.width and y >= 0 and y < map.height do
      lines = String.split(map.map_data, "\n", trim: true)
      line = Enum.at(lines, y)

      if line and x < String.length(line) do
        new_line =
          String.slice(line, 0, x) <> char <> String.slice(line, x + 1, String.length(line))

        new_lines = List.replace_at(lines, y, new_line)
        new_map_data = Enum.join(new_lines, "\n")
        %{map | map_data: new_map_data}
      else
        map
      end
    else
      map
    end
  end

  @doc """
  Gets a rectangular region of the map.
  """
  def get_region(map, x, y, width, height) do
    if x >= 0 and y >= 0 and width > 0 and height > 0 and
         x + width <= map.width and y + height <= map.height do
      lines = String.split(map.map_data, "\n", trim: true)
      region_lines = Enum.slice(lines, y, height)
      Enum.map(region_lines, &String.slice(&1, x, width))
    else
      []
    end
  end
end

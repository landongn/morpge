defmodule More.Repo.Migrations.CreateWorldLayers do
  use Ecto.Migration

  def change do
    # Create the base layers table
    create table(:world_layers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :display_name, :string, null: false
      add :description, :text
      add :layer_order, :integer, null: false
      add :is_active, :boolean, default: true, null: false
      # milliseconds
      add :tick_interval, :integer, default: 3000, null: false
      add :metadata, :jsonb, default: fragment("'{}'::jsonb")

      timestamps(type: :utc_datetime)
    end

    # Create unique constraints
    create unique_index(:world_layers, [:name])
    create unique_index(:world_layers, [:layer_order])
    create index(:world_layers, [:is_active])

    # Create the layer maps table
    create table(:layer_maps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :layer_id, references(:world_layers, on_delete: :delete_all, type: :uuid), null: false
      add :zone_name, :string, null: false
      # ASCII map representation
      add :map_data, :text, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :origin_x, :integer, default: 0
      add :origin_y, :integer, default: 0
      add :metadata, :jsonb, default: fragment("'{}'::jsonb")

      timestamps(type: :utc_datetime)
    end

    # Create indexes for layer maps
    create index(:layer_maps, [:layer_id])
    create index(:layer_maps, [:zone_name])
    create unique_index(:layer_maps, [:layer_id, :zone_name])

    # Create the layer entities table for dynamic content
    create table(:layer_entities, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :layer_id, references(:world_layers, on_delete: :delete_all, type: :uuid), null: false
      add :entity_type, :string, null: false
      add :entity_id, :string, null: false
      add :x, :integer, null: false
      add :y, :integer, null: false
      add :zone_name, :string, null: false
      add :properties, :jsonb, default: fragment("'{}'::jsonb")
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    # Create indexes for layer entities
    create index(:layer_entities, [:layer_id])
    create index(:layer_entities, [:zone_name])
    create index(:layer_entities, [:entity_type])
    create index(:layer_entities, [:x, :y])
    create unique_index(:layer_entities, [:layer_id, :entity_id])

    # Create the layer connections table for inter-layer relationships
    create table(:layer_connections, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :source_layer_id, references(:world_layers, on_delete: :delete_all, type: :uuid),
        null: false

      add :target_layer_id, references(:world_layers, on_delete: :delete_all, type: :uuid),
        null: false

      # e.g., "door", "stairs", "portal"
      add :connection_type, :string, null: false
      add :source_x, :integer, null: false
      add :source_y, :integer, null: false
      add :target_x, :integer, null: false
      add :target_y, :integer, null: false
      add :zone_name, :string, null: false
      add :properties, :jsonb, default: fragment("'{}'::jsonb")

      timestamps(type: :utc_datetime)
    end

    # Create indexes for layer connections
    create index(:layer_connections, [:source_layer_id])
    create index(:layer_connections, [:target_layer_id])
    create index(:layer_connections, [:zone_name])
    create index(:layer_connections, [:connection_type])
  end
end

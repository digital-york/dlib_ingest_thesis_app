class AddMetadataonlyToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :metadataonly, :string
  end
end

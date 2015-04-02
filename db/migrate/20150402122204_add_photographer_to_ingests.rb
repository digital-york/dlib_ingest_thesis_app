class AddPhotographerToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :photographer, :string
  end
end

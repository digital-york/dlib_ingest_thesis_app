class AddRightsToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :rights, :string
  end
end

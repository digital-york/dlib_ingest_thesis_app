class AddParentToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :parent, :string
  end
end

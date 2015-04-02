class AddContentToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :content, :string
  end
end

class AddRepositoryToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :repository, :string
  end
end

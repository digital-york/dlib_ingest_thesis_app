class AddFilestoreToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :filestore, :string
  end
end

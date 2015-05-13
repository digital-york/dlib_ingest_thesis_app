class AddDryrunToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :dryrun, :boolean
  end
end

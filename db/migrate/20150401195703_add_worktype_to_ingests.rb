class AddWorktypeToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :worktype, :string
  end
end

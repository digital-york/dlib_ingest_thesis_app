class CreateIngests < ActiveRecord::Migration
  def change
    create_table :ingests do |t|
      t.string :folder
      t.string :file

      t.timestamps null: false
    end
  end
end

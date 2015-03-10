class CreateTheses < ActiveRecord::Migration
  def change
    create_table :theses do |t|
      t.string :name
      t.string :title
      t.string :date
      t.text :abstract
      t.string :degreetype
      t.string :supervisor
      t.string :department
      t.string :subjectkeyword
      t.string :rightsholder
      t.string :licence

      t.timestamps null: false
    end
  end
end

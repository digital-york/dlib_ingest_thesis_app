class AddColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email, :string
    add_column :users, :surname, :string
    add_column :users, :givenname, :string
    add_column :users, :degreetype, :string
    add_column :users, :supervisor, :string
    add_column :users, :department, :string
  end
end

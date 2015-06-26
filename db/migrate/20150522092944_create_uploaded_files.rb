class CreateUploadedFiles < ActiveRecord::Migration
  def change
    create_table :uploaded_files do |t|
      t.string :uf_uid
      t.string :uf_name
      t.string :title
      t.string :original_name
      t.string :tmp_name
      t.string :content_type
      t.string :thumbnail

      t.string :owner
      t.string :main

      t.timestamps null: false
    end
  end
end

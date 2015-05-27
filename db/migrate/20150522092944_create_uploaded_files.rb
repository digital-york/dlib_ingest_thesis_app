class CreateUploadedFiles < ActiveRecord::Migration
  def change
    create_table :uploaded_files do |t|
      t.string :file_uid
      t.string :title

      t.timestamps null: false
    end
  end
end

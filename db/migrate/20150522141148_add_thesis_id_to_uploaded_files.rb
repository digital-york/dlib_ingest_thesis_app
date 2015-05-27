class AddThesisIdToUploadedFiles < ActiveRecord::Migration
  def change
    add_column :uploaded_files, :thesis_id, :integer
  end
end

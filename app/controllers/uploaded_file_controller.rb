class UploadedFileController < ApplicationController
  def destroy
    @uploaded_file = UploadedFile.find(params[:id])
    temp_file = @uploaded_file.tmp_name
    thumbnail = @uploaded_file.thumbnail
    puts "Deleting " + temp_file
    File.delete(temp_file) if File.exist?(temp_file)
    puts "Done."

    if(thumbnail.start_with?('/uploadedfiles/'))
      fullpath = Rails.root.join('public', thumbnail).to_s
      puts "Deleting " + fullpath
      File.delete(fullpath) if File.exist?(fullpath)
      puts "Done."
    end

    @uploaded_file.destroy

    respond_to do |format|
      format.html { redirect_to new_theses_path, notice: 'File was successfully destroyed.' }
      format.json { head :no_content }
      format.js   { render :layout => false}
    end
  end
end

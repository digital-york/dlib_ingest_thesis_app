namespace :thesis_app do
  desc "TODO"
  task importstuff: :environment do

    file_output = VraDatastream.new
    file_output.image.titleset.title = "hello peri"
    puts file_output.to_xml

  end

end

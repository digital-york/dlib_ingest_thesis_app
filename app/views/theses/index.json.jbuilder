json.array!(@theses) do |thesis|
  json.extract! thesis, :id, :name, :title, :date, :abstract, :degreetype, :supervisor, :department, :subjectkeyword, :rightsholder, :licence
  json.url thesis_url(thesis, format: :json)
end

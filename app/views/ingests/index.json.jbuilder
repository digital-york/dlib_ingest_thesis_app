json.array!(@ingests) do |ingest|
  json.extract! ingest, :id, :folder, :file
  json.url ingest_url(ingest, format: :json)
end

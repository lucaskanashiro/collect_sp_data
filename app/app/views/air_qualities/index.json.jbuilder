json.array!(@air_qualities) do |air_quality|
  json.extract! air_quality, :id, :region, :quality, :index, :polluting
  json.url air_quality_url(air_quality, format: :json)
end

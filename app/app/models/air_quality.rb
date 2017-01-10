class AirQuality
  include Mongoid::Document
  store_in collection: "air_quality"
  field :region, type: String
  field :quality, type: String
  field :index, type: String
  field :polluting, type: String
  field :timestamp, type: String
end

class BikeStation
  include Mongoid::Document
  store_in collection: "bike_stations"
  field :free_bikes, type: Integer
  field :empty_slots, type: Integer
  field :extra, type: Hash
  field :latitude, type: Float
  field :longitude, type: Float
  field :timestamp, type: String
end

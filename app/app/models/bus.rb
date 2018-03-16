class Bus
  include Mongoid::Document
  store_in collection: "olho_vivo"
  field :prefix, type: String
  field :lat, type: Float
  field :lon, type: Float
  field :display, type: String
  field :identifier_code, type: String
  field :display_origin, type: String
  field :display_destination, type: String
  field :vehicles_count, type: Integer
  field :direction, type: Integer
  field :timestamp, type: String
end

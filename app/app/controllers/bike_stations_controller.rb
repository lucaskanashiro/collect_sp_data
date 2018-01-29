class BikeStationsController < ApplicationController
  # GET /bike_stations
  # GET /bike_stations.json
  def index
    @bike_stations = BikeStation.paginate(:page => params[:page], :per_page => 50)
  end
end

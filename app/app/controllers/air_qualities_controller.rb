class AirQualitiesController < ApplicationController
  before_action :set_air_quality, only: [:show]

  # GET /air_qualities
  # GET /air_qualities.json
  def index
    @air_qualities = AirQuality.paginate(:page => params[:page], :per_page => 50)
  end
end

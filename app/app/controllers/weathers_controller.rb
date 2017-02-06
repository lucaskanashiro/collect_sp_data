class WeathersController < ApplicationController
  before_action :set_weather, only: [:show]

  # GET /weathers
  # GET /weathers.json
  def index
    @weathers = Weather.paginate(:page => params[:page], :per_page => 50)
  end
end

require 'test_helper'

class AirQualitiesControllerTest < ActionController::TestCase
  setup do
    @air_quality = air_qualities(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:air_qualities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create air_quality" do
    assert_difference('AirQuality.count') do
      post :create, air_quality: { index: @air_quality.index, polluting: @air_quality.polluting, quality: @air_quality.quality, region: @air_quality.region }
    end

    assert_redirected_to air_quality_path(assigns(:air_quality))
  end

  test "should show air_quality" do
    get :show, id: @air_quality
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @air_quality
    assert_response :success
  end

  test "should update air_quality" do
    patch :update, id: @air_quality, air_quality: { index: @air_quality.index, polluting: @air_quality.polluting, quality: @air_quality.quality, region: @air_quality.region }
    assert_redirected_to air_quality_path(assigns(:air_quality))
  end

  test "should destroy air_quality" do
    assert_difference('AirQuality.count', -1) do
      delete :destroy, id: @air_quality
    end

    assert_redirected_to air_qualities_path
  end
end

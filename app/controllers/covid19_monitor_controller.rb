class Covid19MonitorController < ApplicationController

  Covid19MonitorControllerHelper.initialize_controller

  def change_area_id(area_id)
    area_id = area_id || area_id('world')
    Globals.set(:area_id,area_id)
    Globals.set(:area_display_name, area_display_name(area_id))
  end

  def home
    change_area_id(nil)
  end

  def select_area
    area_id = params['id'].to_i
    change_area_id(area_id)
    render "home"
  end

  def unselect_area
    area_id = params['id'].to_i
    parent_area_id = Area.find(area_id).parent_area_id
    change_area_id(parent_area_id)
    render "home"
  end

  def set_interval
    Globals.set(:data_interval,params[:interval])
    @msg = { "success" => "true", "chart" => create_cases_chart('covid-19-chart',Globals.get(:area_id),Globals.get(:data_interval))}
    respond_to do |format|
      format.html
      format.json { render json: @msg }
    end
  end
end

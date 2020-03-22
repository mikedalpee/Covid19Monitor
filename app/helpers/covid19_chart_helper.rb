module Covid19ChartHelper
  include Chartkick::Helper
  include ActionView::Helpers::NumberHelper

  def area_display_name(area_id)
    Area.find(area_id).display_name
  end

  def area_id(name)
    Area.find_by(name: name).area_id
  end

  def create_info_tile()
    world_area_id = Area.find_by(name: "world").area_id
    global_cases = Case.where(area_id: world_area_id, updated_at: Case.select('MAX(updated_at)').where(area_id: world_area_id))&.first
    info_tile =
      %&<div class="title" title="Total Confirmed Cases">Total Confirmed Cases</div>
        <div class="confirmed">#{number_with_delimiter(global_cases&.active+global_cases&.recovered+global_cases&.fatal)}</div>
        <div class="legend">
          <div class="color" style="background: orange;"></div>
          <div class="description">Active cases</div>
          <div class="total">#{number_with_delimiter(global_cases&.active)}</div>
          <div class="color" style="background: green;"></div>
          <div class="description">Recovered cases</div>
          <div class="total">#{number_with_delimiter(global_cases&.recovered)}</div>
          <div class="color" style="background: red;"></div>
          <div class="description">Fatal cases</div>
          <div class="total">#{number_with_delimiter(global_cases&.fatal)}</div>
        </div>
      &
    return info_tile.html_safe
  end

  def create_area_buttons_str(area_id,level)
    style = level > 0 ? %& style="padding-left: #{level*10}px"& : ""
    area_buttons = %&<div class="bd-toc-item"#{style}>&
    area = Area.find(area_id)
    area_buttons += link_to(area.display_name, select_area_path(area.area_id), id: area.name, class: 'bd-toc-link')
    area_buttons +='</div>'
    Area.where(parent_area_id: area_id).order(:display_name).each() do |child_area|
      area_buttons += create_area_buttons_str(child_area.area_id,level+1)
    end
    area_buttons
  end

  def create_area_buttons(area_id)
    return create_area_buttons_str(area_id,0).html_safe
  end

  def create_cases_chart(chart_id,area_id)
    Rails.logger.log(Logger::INFO,"Creating cases chart")
    active = {}
    fatal = {}
    recovered= {}
    Case.where(area_id: area_id).select("updated_at,active,recovered,fatal").each do |element|
      updated_at = element['updated_at'].to_s
      active[updated_at] = element['active']
      fatal[updated_at] = element['fatal']
      recovered[updated_at] = element['recovered']
    end
    data = [
        {name: "Active", data: active},
        {name: "Recovered", data: recovered},
        {name: "Fatal", data: fatal}
    ]

    line_chart data, id: chart_id, height: "75vh", width: "75vw", colors: ['orange','green','red'],xtitle: 'Time', ytitle:'Cases', title: Globals.get(:area_display_name), points: false
  end

end
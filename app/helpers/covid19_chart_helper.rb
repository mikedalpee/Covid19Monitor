module Covid19ChartHelper
  include Chartkick::Helper
  include ActionView::Helpers::NumberHelper

  def area_display_name(area_id)
    Area.find(area_id).display_name
  end

  def area_id(name)
    Area.find_by(name: name).area_id
  end

  def create_info_tile(area_id)
    cases = Case.where(area_id: area_id, updated_at: Case.select('MAX(updated_at)').where(area_id: area_id))&.first
    total_confirmed = cases&.active+cases&.recovered+cases&.fatal
    info_tile =
      %&<div class="title" title="Total Confirmed Cases">Total Confirmed Cases</div>
        <div class="confirmed">#{number_with_delimiter(total_confirmed)}</div>
        <div class="legend">
          <div class="color" style="background: orange;"></div>
          <div class="description">Active cases</div>
          <div class="total">#{number_with_delimiter(cases&.active)}</div>
          <div class="total">(#{number_to_percentage(cases&.active.to_f/total_confirmed*100.0)})</div>
          <div class="color" style="background: green;"></div>
          <div class="description">Recovered cases</div>
          <div class="total">#{number_with_delimiter(cases&.recovered)}</div>
          <div class="total">(#{number_to_percentage(cases&.recovered.to_f/total_confirmed*100.0)})</div>
          <div class="color" style="background: red;"></div>
          <div class="description">Fatal cases</div>
          <div class="total">#{number_with_delimiter(cases&.fatal)}</div>
          <div class="total">(#{number_to_percentage(cases&.fatal.to_f/total_confirmed*100.0)})</div>
        </div>
      &
    return info_tile.html_safe
  end

  def create_selected_buttons()
    selected_area = Area.find(Globals.get(:area_id))
    selected_buttons = [selected_area]
    loop do
      parent_area_id = selected_area.parent_area_id
      break if parent_area_id.nil?
      selected_area = Area.find(selected_area.parent_area_id)
      selected_buttons.prepend(selected_area)
    end

    selected_buttons_str = ""
    first_button = true

    selected_buttons.each do |area|
      selected_buttons_str += '<div class=>'
      selected_buttons_str += link_to(area.display_name,unselect_area_path(area.id), id: area.name, style: "color: black;")
      selected_buttons_str +='</div>'
    end
    selected_buttons_str.html_safe
  end

  def create_area_buttons(area_id)
    immediate_child_areas = Area.where(parent_area_id: area_id).order(:display_name)
    area_buttons_str = ""
    immediate_child_areas.each do |child_area|
      area_buttons_str += '<div>'
      area_buttons_str += link_to(child_area.display_name, select_area_path(child_area.area_id), id: child_area.name, style: "color: black;")
      area_buttons_str +='</div>'
    end
    area_buttons_str.html_safe
  end

  def create_cases_chart(chart_id,area_id,interval)
    Rails.logger.log(Logger::INFO,"Creating cases chart")
    active = {}
    fatal = {}
    recovered= {}
    data_filter =  <<-SQL
      WITH RECURSIVE data_filter(area_id, updated_at, active, recovered, fatal) AS (
        SELECT cases.area_id, cases.updated_at, cases.active, cases.recovered, cases.fatal
        FROM
          (SELECT area_id, MIN(updated_at) as updated_at
           FROM cases
           GROUP BY area_id HAVING area_id = #{area_id}) base_cases
          JOIN cases ON (base_cases.area_id = cases.area_id AND base_cases.updated_at = cases.updated_at)
        UNION ALL
          (SELECT cases.area_id, cases.updated_at, cases.active, cases.recovered, cases.fatal
           FROM cases
           JOIN data_filter ON (cases.area_id = data_filter.area_id AND cases.updated_at >= (data_filter.updated_at + INTERVAL '#{interval}'))
           ORDER BY cases.updated_at
           LIMIT 1)
      )
      SELECT * FROM data_filter
    SQL

    ActiveRecord::Base.connection.execute(data_filter).each do |element|
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

    line_chart data, id: chart_id, height: "75vh", width: "75vw", margin: 0, colors: ['orange','green','red'],xtitle: 'Time', ytitle:'Cases', title: Globals.get(:area_display_name), points: false
  end

  def option(interval,label)
    '<option value="'+interval+'"'+(Globals.get(:data_interval) == interval ? " selected" : "")+'>'+label+'</option>'
  end

  def create_interval_options()
    option_str  = option("6 hours","Every 6 Hours")
    option_str += option("12 hours","Every 12 Hours")
    option_str += option("1 day","Every Day")
    option_str += option("1 week","Every Week")
    option_str += option("1 month","Every Month")
    option_str.html_safe
  end

end
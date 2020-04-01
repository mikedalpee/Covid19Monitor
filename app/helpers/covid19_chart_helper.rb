module Covid19ChartHelper
  include Chartkick::Helper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper

  def area_display_name(area_id)
    Area.find(area_id).display_name
  end

  def area_id(name)
    Area.find_by(name: name).area_id
  end

  def ratio(numerator,denominator)
    fraction = 0.0
    if denominator.to_f != 0.0
      fraction = (numerator.to_f/denominator.to_f)
    end
    fraction
  end

  def percentage(numerator,denominator)
    number_to_percentage((ratio(numerator,denominator)*100.0).round(1),precision: 1)
  end

  def progression(samples)
    ratio(samples[0].to_i+samples[1].to_i,samples[2].to_i+samples[3].to_i)
  end

  def collect_samples(samples, value, updated_at)
    if samples[:last_value].nil?
      samples[:last_value] = value
      samples[:last_update] = updated_at
    else
      delta_t = samples[:last_update] - updated_at
      delta_a = samples[:last_value] - value
      samples[:total_elapsed_sample_time] += delta_t
      samples[:samples_total] += delta_a
      if (samples[:total_elapsed_sample_time]/86400).floor > samples[:samples_per_day].length
        samples[:samples_per_day].push(samples[:samples_total])
        samples[:samples_total] = 0
      end
      samples[:last_value] = value
      samples[:last_update] = updated_at
    end
  end

  def create_info_tile()
    area_id = Globals.get(:area_id)
    cases = Case.where(area_id: area_id).distinct.order(updated_at: :desc)
    latest_case = cases.first
    total_confirmed = latest_case&.active+latest_case&.recovered+latest_case&.fatal
    active_samples = {last_value: nil, last_update: nil, samples_total: 0, samples_per_day: [], total_elapsed_sample_time: 0.0}
    recovered_samples = {last_value: nil, last_update: nil, samples_total: 0, samples_per_day: [], total_elapsed_sample_time: 0.0}
    fatal_samples = {last_value: nil, last_update: nil, samples_total: 0, samples_per_day: [], total_elapsed_sample_time: 0.0}
    active_done = false
    recovered_done = false
    fatal_done = false
    cases.each do |a_case|
      break if active_done && recovered_done && fatal_done

      if !active_done
        collect_samples(active_samples, a_case.active, a_case.updated_at)
        active_done = active_samples[:total_elapsed_sample_time] >= 86400*4 #4 days
      end

      if !recovered_done
        collect_samples(recovered_samples, a_case.recovered, a_case.updated_at)
        recovered_done = recovered_samples[:total_elapsed_sample_time] >= 86400*4 #4 days
      end

      if !fatal_done
        collect_samples(fatal_samples, a_case.fatal, a_case.updated_at)
        fatal_done = fatal_samples[:total_elapsed_sample_time] >= 86400*4 #4 days
      end
    end

    info_tile =
      %&<div class="title" title="Total Confirmed Cases">Total Confirmed Cases</div>
        <div class="confirmed">#{number_with_delimiter(total_confirmed)}</div>
        <div class="legend">
          <div class="color" style="background: orange;"></div>
          <div class="description">Active cases</div>
          <div class="total">#{number_with_delimiter(latest_case&.active)}</div>
          <div class="total">(#{percentage(latest_case&.active,total_confirmed)})</div>
          <div class="total">(#{active_samples[:samples_per_day][0]})</div>
          <div class="total">(#{progression(active_samples[:samples_per_day]).round(1)})</div>
          <div class="color" style="background: green;"></div>
          <div class="description">Recovered cases</div>
          <div class="total">#{number_with_delimiter(latest_case&.recovered)}</div>
          <div class="total">(#{percentage(latest_case&.recovered,total_confirmed)})</div>
          <div class="total">(#{recovered_samples[:samples_per_day][0]})</div>
          <div class="total">(#{progression(recovered_samples[:samples_per_day]).round(1)})</div>
          <div class="color" style="background: red;"></div>
          <div class="description">Fatal cases</div>
          <div class="total">#{number_with_delimiter(latest_case&.fatal)}</div>
          <div class="total">(#{percentage(latest_case&.fatal,total_confirmed)})</div>
          <div class="total">(#{fatal_samples[:samples_per_day][0]})</div>
          <div class="total">(#{progression(fatal_samples[:samples_per_day]).round(1)})</div>
        </div>
      &
    return info_tile.html_safe
  end

  def create_selected_buttons()
    selected_area_id = Globals.get(:area_id)
    selected_area = Area.find(selected_area_id)
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

  def create_area_buttons()
    area_id = Globals.get(:area_id)
    immediate_child_areas = Area.where(parent_area_id: area_id).order(:display_name)
    area_buttons_str = ""
    immediate_child_areas.each do |child_area|
      area_buttons_str += '<div>'
      area_buttons_str += link_to(child_area.display_name, select_area_path(child_area.area_id), id: child_area.name, style: "color: black;")
      area_buttons_str +='</div>'
    end
    area_buttons_str.html_safe
  end

  def create_chart_title(area_id)
    title = area_display_name(area_id)
    query_duplicates = Globals.get(:query_duplicates)
    if query_duplicates > 0
      title += " (#{query_duplicates} other#{query_duplicates > 1 ? 's' : ''})"
    end
    title
  end

  def create_cases_chart()
    chart_id = 'covid-19-chart'
    area_id = Globals.get(:area_id)
    interval = Globals.get(:data_interval)
    title = create_chart_title(area_id)
    Rails.logger.log(Logger::INFO,"Creating cases chart")
    active = {}
    fatal = {}
    recovered= {}
    data_filter =  <<-SQL
      WITH RECURSIVE data_filter(area_id, updated_at, active, recovered, fatal) AS (
        SELECT cases.area_id,cases.updated_at,active,recovered,fatal
        FROM
          (SELECT area_id, MIN(updated_at) as updated_at
           FROM cases
           GROUP BY area_id HAVING area_id = #{area_id}) base_cases,cases 
          WHERE base_cases.area_id = cases.area_id AND base_cases.updated_at = cases.updated_at
        UNION (
          SELECT cases.area_id, cases.updated_at, cases.active, cases.recovered, cases.fatal
          FROM cases,data_filter,
             (SELECT max_case.area_id,max_case.updated_at,active,recovered,fatal
                FROM
                (SELECT area_id, MAX(updated_at) as updated_at
                 FROM cases
                 GROUP BY area_id HAVING area_id = #{area_id}) base_cases,cases max_case
               WHERE base_cases.area_id = max_case.area_id AND base_cases.updated_at = max_case.updated_at) full_max_case
          WHERE cases.area_id = data_filter.area_id AND (cases.updated_at >= (data_filter.updated_at + INTERVAL '#{interval}') or cases.updated_at = full_max_case.updated_at)
          ORDER BY cases.updated_at
          LIMIT 1))
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

    line_chart data, id: chart_id, height: "75vh", width: "75vw", margin: 0, colors: ['orange','green','red'],xtitle: 'Time', ytitle:'Cases', title: title, points: false
  end

  def option(value,label,selected)
    '<option value="'+value+'"'+ (selected == value ? " selected" : "")+'>'+label+'</option>'
  end

  def create_interval_options()
    selected = Globals.get(:data_interval)
    option_str  = option("6 hours","Every 6 Hours",selected)
    option_str += option("12 hours","Every 12 Hours",selected)
    option_str += option("1 day","Daily",selected)
    option_str += option("1 week","Weekly",selected)
    option_str += option("1 month","Monthly",selected)
    option_str.html_safe
  end

  def create_query_options()
    selected = Globals.get(:query_id)
    option_str = option("none","None",selected)
    option_str += option("hac","Highest Active Cases",selected)
    option_str += option("hap","Highest Active Case Percentage",selected)
    option_str += option("lac","Lowest Active Cases",selected)
    option_str += option("lap","Lowest Active Case Percentage",selected)
    option_str += option("hrc","Highest Recovered Cases",selected)
    option_str += option("hrp","Highest Recovered Case Percentage",selected)
    option_str += option("lrc","Lowest Recovered Cases",selected)
    option_str += option("lrp","Lowest Recovered Case Percentage",selected)
    option_str += option("hfc","Highest Fatal Cases",selected)
    option_str += option("hfp","Highest Fatal Case Percentage",selected)
    option_str += option("lfc","Lowest Fatal Cases",selected)
    option_str += option("lfp","Lowest Fatal Case Percentage",selected)
    option_str += option("htc","Highest Total Confirmed Cases",selected)
    option_str += option("ltc","Lowest Total Confirmed Cases",selected)
    option_str.html_safe
  end

end
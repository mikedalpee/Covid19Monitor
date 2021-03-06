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

  def change(samples)
    samples[0].to_i+samples[1].to_i
  end

  def rate(samples)
    ratio(samples[0].to_i+samples[1].to_i,samples[2].to_i+samples[3].to_i)
  end

  def projection(value,rate,n)
    value*((1+rate)**n)
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

  def create_info_tile
    area_id = Globals.get(:area_id)
    start_date = Globals.get(:start_date)
    end_date = Globals.get(:end_date)
    active_samples = {last_value: nil, last_update: nil, samples_total: 0, samples_per_day: [], total_elapsed_sample_time: 0.0}
    recovered_samples = {last_value: nil, last_update: nil, samples_total: 0, samples_per_day: [], total_elapsed_sample_time: 0.0}
    fatal_samples = {last_value: nil, last_update: nil, samples_total: 0, samples_per_day: [], total_elapsed_sample_time: 0.0}
    active_done = false
    recovered_done = false
    fatal_done = false
    active = 0
    recovered = 0
    fatal = 0
    cases = Case.where("area_id = #{area_id} AND updated_at BETWEEN '#{start_date}' AND '#{end_date}'").distinct.order(updated_at: :desc)
    latest_case = cases.first
    if latest_case.nil?
      Rails.logger.log(Logger::ERROR, "Unable to retrieve between start date '#{start_date}' and end date '#{end_date}'")
    else
      active = (latest_case&.active).to_i
      recovered = (latest_case&.recovered).to_i
      fatal = (latest_case&.fatal).to_i
    end

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
    total_confirmed = active+recovered+fatal
    info_tile =
      %&<div class="title" title="Total Confirmed Cases">Total Confirmed Cases</div>
        <div class="confirmed">#{number_with_delimiter(total_confirmed)}</div>
        <div class="legend">
          <div class="color" style="background: orange;"></div>
          <div class="description">Active cases</div>
          <div class="total">#{number_with_delimiter(active)}</div>
          <div class="total">(#{percentage(active,total_confirmed)})</div>
          <div class="total">(#{number_with_delimiter(change(active_samples[:samples_per_day]))})</div>
          <div class="total">(#{rate(active_samples[:samples_per_day]).round(1)})</div>
          <div class="total">(#{number_with_delimiter(projection(active,rate(fatal_samples[:samples_per_day]),2).round)})</div>
          <div class="color" style="background: green;"></div>
          <div class="description">Recovered cases</div>
          <div class="total">#{number_with_delimiter(recovered)}</div>
          <div class="total">(#{percentage(recovered,total_confirmed)})</div>
          <div class="total">(#{number_with_delimiter(change(recovered_samples[:samples_per_day]))})</div>
          <div class="total">(#{rate(recovered_samples[:samples_per_day]).round(1)})</div>
          <div class="total">(#{number_with_delimiter(projection(recovered,rate(fatal_samples[:samples_per_day]),2).round)})</div>
          <div class="color" style="background: red;"></div>
          <div class="description">Fatal cases</div>
          <div class="total">#{number_with_delimiter(fatal)}</div>
          <div class="total">(#{percentage(fatal,total_confirmed)})</div>
          <div class="total">(#{number_with_delimiter(change(fatal_samples[:samples_per_day]))})</div>
          <div class="total">(#{rate(fatal_samples[:samples_per_day]).round(1)})</div>
          <div class="total">(#{number_with_delimiter(projection(fatal,rate(fatal_samples[:samples_per_day]),2).round)})</div>
        </div>
      &
    return info_tile.html_safe
  end

  def create_selected_buttons
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

  def create_area_buttons
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

  def create_cases_chart
    chart_id = 'covid-19-chart'
    area_id = Globals.get(:area_id)
    interval = Globals.get(:data_interval)
    start_date = Globals.get(:start_date)
    end_date = Globals.get(:end_date)
    title = create_chart_title(area_id)
    Rails.logger.log(Logger::INFO,"Creating cases chart")
    active = {}
    fatal = {}
    recovered= {}
    data_filter =  <<-SQL
       WITH RECURSIVE data_filter(area_id, updated_at, active, recovered, fatal) AS (
        (SELECT area_id,updated_at,active,recovered,fatal
         FROM cases
         WHERE area_id = #{area_id} AND updated_at >= '#{start_date}'
         ORDER BY updated_at
         LIMIT 1)
        UNION
        (SELECT c.area_id, c.updated_at, c.active, c.recovered, c.fatal
         FROM (SELECT * FROM data_filter ORDER BY updated_at DESC) df JOIN cases c ON df.area_id = c.area_id
		     WHERE c.updated_at >= (df.updated_at + INTERVAL '#{interval}') OR 
		           c.updated_at = (SELECT updated_at
							                 FROM cases 
							                 WHERE area_id = #{area_id} AND updated_at <= '#{end_date}' 
							                 ORDER BY updated_at DESC
							                 LIMIT 1)
         ORDER BY c.updated_at
		     LIMIT 1)
	     )
       SELECT * FROM data_filter ORDER BY updated_at
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

  def create_interval_options
    selected = Globals.get(:data_interval)
    option_str  = option("6 hours","Every 6 Hours",selected)
    option_str += option("12 hours","Every 12 Hours",selected)
    option_str += option("1 day","Daily",selected)
    option_str += option("1 week","Weekly",selected)
    option_str += option("1 month","Monthly",selected)
    option_str.html_safe
  end

  def create_query_options
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

  def date_format
    "YYYY-MM-DD"
  end

  def create_daterangepicker_options
    options = <<-OPT
      {locale: {format: '#{date_format}'},minDate: '#{Globals.get(:min_start_date)}',startDate: '#{Globals.get(:start_date)}',maxDate: '#{Globals.get(:max_end_date)}',endDate: '#{Globals.get(:end_date)}', drops: 'up'}
    OPT

    options.gsub(/[\n]/,'')
  end

  def create_daterangepicker_javascript
    javascript = <<-SCRIPT
      <script>
        $(function() {
          $('#covid19-date-range').daterangepicker(
            #{create_daterangepicker_options},
            function(start,end,label){
              var date_format = '#{date_format}';
              var url='/set_date_range/'+encodeURIComponent(start.format(date_format))+'/'+encodeURIComponent(end.format(date_format));
              location.replace(url)
            })
        })
      </script>
    SCRIPT
    javascript.html_safe
  end

end
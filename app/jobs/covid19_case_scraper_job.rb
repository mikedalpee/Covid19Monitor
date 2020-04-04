class Covid19CaseScraperJob
  include SuckerPunch::Job
  require File.expand_path('../../helpers/watir', __FILE__)
  include Covid19ChartHelper
  include ActiveSupport::Inflector
  require 'open-uri'


  URL="https://www.bing.com/covid"
  USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36"
  CASE_UPDATE_INTERVAL = 60*5 #5 minutes

  def process_cases(area)
    selected_changed = false
    a = (Area.find_by(name: area['id']) || Area.new(name: area['id']))
    if !area['parentId'].nil?
      p =  Area.find_by(name: area['parentId'])
      a.parent_area_id = p.area_id
    end
    a.display_name = area['displayName'].titleize
    a.save!
    c = Case.new
    c.area_id = a.area_id
    c.fatal = area['totalDeaths'].to_i
    c.recovered = area['totalRecovered'].to_i
    c.active = area['totalConfirmed'].to_i - c.fatal - c.recovered
    c.updated_at = area['lastUpdated']
    begin
      c.save!
      selected_changed = (c.area_id == Globals.get(:area_id))
    rescue ActiveRecord::RecordNotUnique => e #Data didn't change from last check
      #Rails.logger.log(Logger::WARN,"Data for #{area['id']} hasn't been updated since last update at #{c.updated_at}/#{area['lastUpdated']}")
    rescue => e
      Rails.logger.log(Logger::ERROR, "Case could not be added to database: #{e}")
    end
    area['areas']&.each do |area|
      selected_changed_below = process_cases(area)
      selected_changed ||= selected_changed_below
    end
    return selected_changed
  end

  def get_covid_data
    page = Nokogiri::HTML(URI.open(URL,'User-Agent' => USER_AGENT, read_timeout: 10))
    scripts = page.xpath("//head/script")
    token_script = nil
    scripts.each do |script|
      if script.text.include?("var ig=")
        token_script = script.text
        break
      end
    end

    if token_script.nil?
      raise "Could not locate token script"
    end

    ig = nil
    token = nil

    /\"(?<ig>.*)".*token='(?<token>.*)'/ =~ token_script

    token = Base64.strict_encode64(token)
    page = Nokogiri::HTML(URI.open(URL+"/data?ig=#{ig}",'User-Agent' => USER_AGENT, 'Authorization' => "Basic "+token, read_timeout: 10))
    page.text
  end

  def perform(*args)
    loop do
      begin
        Rails.logger.log(Logger::INFO, "Pulling COVID-19 Data")
        json = get_covid_data()
        Rails.logger.log(Logger::INFO, "Updating COVID-19 Database")
        selected_changed = process_cases(JSON.parse(json))
        if selected_changed
          Rails.logger.log(Logger::INFO, "Data for selected area #{area_display_name(Globals.get(:area_id))} changed.")
          max_date = Case.where(area_id: Globals.get(:area_id)).maximum("updated_at").strftime('%Y-%m-%d %H:%M:%S.%L%z')
          Y           Globals.set(:max_end_date,max_date)
          ActionCable.server.broadcast(
            "Covid19ChartUpdateChannel",
            {daterangepicker_javascript: create_daterangepicker_javascript,
             cases_chart: create_cases_chart,
             info_tile: create_info_tile})
        end
      rescue => e
        Rails.logger.log(Logger::INFO, "Unable to get covid data due to exception: #{e}")
        next
      end
      sleep(CASE_UPDATE_INTERVAL)
    end
  end
end
class Covid19CaseScraperJob
  include SuckerPunch::Job
  require File.expand_path('../../helpers/watir', __FILE__)
  include Covid19ChartHelper
  include ActiveSupport::Inflector

  URL="https://www.bing.com/covid/data?IG=138A57D12AAC48F0A60D4B9803277546"
  CASE_UPDATE_INTERVAL = 60*5 #5 minutes

  def process_cases(area)
    selected_changed = false
    global_changed = false
    a = (Area.find_by(name: area['id']) || Area.new(name: area['id']))
    if !area['parentId'].nil?
      p =  Area.find_by(name: area['parentId'])
      a.parent_area_id = p.area_id
    end
    a.display_name = area['displayName'].titleize
    a.save!
    c = Case.new
    c.area_id = a.area_id
    c.fatal = area['totalDeaths']
    c.recovered = area['totalRecovered']
    c.active = area['totalConfirmed'] - c.fatal - c.recovered
    c.updated_at = area['lastUpdated']
    begin
      c.save!
      selected_changed = (a.area_id == Globals.get(:area_id))
      global_changed = (a.area_id == Globals.get(:global_area_id))
    rescue ActiveRecord::RecordNotUnique => e #Data didn't change from last check
      Rails.logger.log(Logger::WARN,"Data for #{area['id']} hasn't been updated since last update at #{c.updated_at}/#{area['lastUpdated']}")
    rescue => e
      Rails.logger.log(Logger::ERROR, "Case could not be added to database: #{e}")
    end
    area['areas']&.each do |area|
      selected_changed_below,global_changed_below = process_cases(area)
      selected_changed ||= selected_changed_below
      global_changed ||= global_changed_below
    end
    return selected_changed,global_changed
  end

  def perform(*args)
    session = ScrapeSession.new(headless: true)
    while !session.terminated?
      session.open
      session.goto_url(URL)
      if (json = session.browser.element(xpath: "//pre")).exists?
        Rails.logger.log(Logger::INFO, "Updating COVID-19 Database")
        selected_changed,global_changed = process_cases(JSON.parse(json.text))
        if selected_changed
          Rails.logger.log(Logger::INFO, "Data for selected area #{Globals.get(:area_display_name)} changed.")
          ActionCable.server.broadcast "Covid19ChartUpdateChannel", selected: create_cases_chart('covid-19-chart',Globals.get(:area_id))
        end
        if global_changed
          Rails.logger.log(Logger::INFO, "Data for the Global area changed.")
          ActionCable.server.broadcast "Covid19ChartUpdateChannel", global: create_info_tile(Globals.get(:area_id))
        end
      else
        Rails.logger.log(Logger::ERROR, "No COVID-19 data found using url #{URL}")
      end
      session.close
      sleep(CASE_UPDATE_INTERVAL)
    end
  end
end
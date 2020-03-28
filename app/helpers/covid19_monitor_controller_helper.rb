module Covid19MonitorControllerHelper
  def self.initialize_controller
    Globals.set(:data_interval,"12 hours")
    Globals.set(:query_id,"none")
    Globals.set(:query_duplicates,0)
    Globals.set(:area_id,1)
    Covid19CaseScraperJob::perform_async
  end
end
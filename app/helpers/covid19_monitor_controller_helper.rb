module Covid19MonitorControllerHelper
  def self.initialize_controller
    Globals.set(:data_interval,"12 hours")
    Covid19CaseScraperJob::perform_async
  end
end
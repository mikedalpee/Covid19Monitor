module Covid19MonitorControllerHelper

  def self.set_date_range_for_area(area_id)
    min_date = Case.where(area_id: area_id).minimum("updated_at").strftime('%Y-%m-%d')+" 00:00:00.000+0000"
    max_date = Case.where(area_id: area_id).maximum("updated_at").strftime('%Y-%m-%d')+" 23:59:59.999+0000"
    Globals.set(:min_start_date,min_date)
    Globals.set(:max_end_date,max_date)
    start_date = Globals.get(:start_date)
    if start_date.nil? || DateTime.parse(min_date) > DateTime.parse(start_date)
      Globals.set(:start_date,min_date)
    end
    end_date = Globals.get(:end_date)
    if end_date.nil? || DateTime.parse(max_date) < DateTime.parse(end_date)
      Globals.set(:end_date,max_date)
    end
  end

  def self.initialize_controller
    Globals.set(:data_interval,"1 day")
    Globals.set(:query_id,"none")
    Globals.set(:query_duplicates,0)
    Globals.set(:area_id,1)
    Covid19MonitorControllerHelper.set_date_range_for_area(Globals.get(:area_id))
    Covid19CaseScraperJob::perform_async
  end
end
class Covid19MonitorController < ApplicationController
  @@first_call = true
  def home
    if @@first_call
      Globals.set(:area_id,area_id('world'))
      Globals.set(:area_display_name, area_display_name(Globals.get(:area_id)))
      Globals.set(:global_area_id,Globals.get(:area_id))
      Covid19CaseScraperJob::perform_async
      @@first_call = false
    else
      if params.key?('id')
        area_id = params['id'].to_i
        Globals.set(:area_id,area_id)
        Globals.set(:area_display_name, area_display_name(Globals.get(:area_id)))
      end
    end
  end
end

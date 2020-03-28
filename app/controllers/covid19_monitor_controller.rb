class Covid19MonitorController < ApplicationController

  Covid19MonitorControllerHelper.initialize_controller

  def change_area_id(area_id)
    area_id = area_id || area_id('world')
    Globals.set(:area_id,area_id)
  end

  def home
    change_area_id(Globals.get(:area_id))
  end

  def select_area
    area_id = params['id'].to_i
    change_area_id(area_id)
    Globals.set(:query_id,"none")
    Globals.set(:query_duplicates,0)
    render "home"
  end

  def unselect_area
    area_id = params['id'].to_i
    parent_area_id = Area.find(area_id).parent_area_id
    change_area_id(parent_area_id)
    Globals.set(:query_id,"none")
    Globals.set(:query_duplicates,0)
    render "home"
  end

  def set_interval
    Globals.set(:data_interval,params[:interval])
    render "home"
  end

  def process_query(query)
    recs = ActiveRecord::Base.connection.execute(query)
    if recs.count > 0
      area_id = recs[0]['area_id'].to_i
      change_area_id(area_id)
      target_value = recs[0]['target_value']
      target_value_count = 0
      recs.each do |rec|
        break if rec['target_value'] != target_value
        target_value_count += 1
      end
      Globals.set(:query_duplicates,target_value_count-1)
    end
  end

  def create_query(magnitude,column)
    if magnitude == :highest
      function = "MAX"
      order = "DESC"
    else
      function = "MIN"
      order = "ASC"
    end
    <<-SQL
        SELECT c.area_id, #{function}(#{column}) target_value 
        FROM areas a, cases c 
        WHERE c.area_id = a.area_id AND a.parent_area_id = 1 AND (c.area_id,updated_at) IN 
          (SELECT area_id, MAX(updated_at) max_updated_at 
           FROM cases 
           GROUP BY area_id) 
        GROUP BY c.area_id 
        ORDER BY target_value #{order}
    SQL
  end

  def set_query
    query_id = params[:query_id]
    Globals.set(:query_id,query_id)
    case query_id
    when "hac"
      query = create_query(:highest,"active")
      process_query(query)
    when "hap"
      query = create_query(:highest,"CAST(active AS FLOAT)/(active+recovered+fatal)")
      process_query(query)
    when "lac"
      query = create_query(:lowest,"active")
      process_query(query)
    when "lap"
      query = create_query(:lowest,"CAST(active AS FLOAT)/(active+recovered+fatal)")
      process_query(query)
    when "hrc"
      query = create_query(:highest,"recovered")
      process_query(query)
    when "hrp"
      query = create_query(:highest,"CAST(recovered AS FLOAT)/(active+recovered+fatal)")
      process_query(query)
    when "lrc"
      query = create_query(:lowest,"recovered")
      process_query(query)
    when "lrp"
      query = create_query(:lowest,"CAST(recovered AS FLOAT)/(active+recovered+fatal)")
      process_query(query)
    when "hfc"
      query = create_query(:highest,"fatal")
      process_query(query)
    when "hfp"
      query = create_query(:highest,"CAST(fatal AS FLOAT)/(active+recovered+fatal)")
      process_query(query)
    when "lfc"
      query = create_query(:lowest,"fatal")
      process_query(query)
    when "lfp"
      query = create_query(:lowest,"CAST(fatal AS FLOAT)/(active+recovered+fatal)")
      process_query(query)
    when "htc"
      query = create_query(:highest,"active+recovered+fatal")
      process_query(query)
    when "ltc"
      query = create_query(:lowest,"active+recovered+fatal")
      process_query(query)
    when "none"
      Globals.set(:query_duplicates,0)
    end

    render "home"
  end
end

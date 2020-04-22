class Covid19MonitorController < ApplicationController

  Covid19MonitorControllerHelper.initialize_controller

  def change_area_id(area_id)
    area_id = area_id || area_id('world')
    Globals.set(:area_id,area_id)
    Covid19MonitorControllerHelper.set_date_range_for_area(Globals.get(:area_id))
  end

  def home
  end

  def select_area
    area_id = params['id'].to_i
    change_area_id(area_id)
    Globals.set(:query_id,"none")
    Globals.set(:query_duplicates,0)
    redirect_to root_path
  end

  def unselect_area
    area_id = params['id'].to_i
    parent_area_id = Area.find(area_id).parent_area_id
    change_area_id(parent_area_id)
    Globals.set(:query_id,"none")
    Globals.set(:query_duplicates,0)
    redirect_to root_path
  end

  def set_interval
    Globals.set(:data_interval,params[:interval])
    redirect_to root_path
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
        FROM cases c 
        WHERE c.area_id IN
          (SELECT area_id
           FROM areas
           WHERE parent_area_id = #{Globals.get(:area_id)}) AND (c.area_id,updated_at) IN 
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
      query = create_query(:highest,"COALESCE(CAST(active AS FLOAT)/NULLIF(active+recovered+fatal,0),CAST(0 AS FLOAT))")
      process_query(query)
    when "lac"
      query = create_query(:lowest,"active")
      process_query(query)
    when "lap"
      query = create_query(:lowest,"COALESCE(CAST(active AS FLOAT)/NULLIF(active+recovered+fatal,0),CAST(0 AS FLOAT))")
      process_query(query)
    when "hrc"
      query = create_query(:highest,"recovered")
      process_query(query)
    when "hrp"
      query = create_query(:highest,"COALESCE(CAST(recovered AS FLOAT)/NULLIF(active+recovered+fatal,0),CAST(0 AS FLOAT))")
      process_query(query)
    when "lrc"
      query = create_query(:lowest,"recovered")
      process_query(query)
    when "lrp"
      query = create_query(:lowest,"COALESCE(CAST(recovered AS FLOAT)/NULLIF(active+recovered+fatal,0),CAST(0 AS FLOAT))")
      process_query(query)
    when "hfc"
      query = create_query(:highest,"fatal")
      process_query(query)
    when "hfp"
      query = create_query(:highest,"COALESCE(CAST(fatal AS FLOAT)/NULLIF(active+recovered+fatal,0),CAST(0 AS FLOAT))")
      process_query(query)
    when "lfc"
      query = create_query(:lowest,"fatal")
      process_query(query)
    when "lfp"
      query = create_query(:lowest,"COALESCE(CAST(fatal AS FLOAT)/NULLIF(active+recovered+fatal,0),CAST(0 AS FLOAT))")
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
    redirect_to root_path
  end

  def check_samples(samples, updated_at)
    if samples[:last_update].nil?
      samples[:last_update] = updated_at
     else
      delta_t = samples[:last_update] - updated_at
      samples[:total_elapsed_sample_time] += delta_t
      if (samples[:total_elapsed_sample_time]/86400).floor > samples[:count]
        samples[:count] += 1
      end
      samples[:last_update] = updated_at
    end
  end

  def set_date_range
    start_date = params[:start_date]+" 00:00:00.000+0000"
    end_date = params[:end_date]+" 23:59:59.999+0000"

    area_id = Globals.get(:area_id)
    cases = Case.where("area_id = #{area_id} AND updated_at BETWEEN '#{start_date}' AND '#{end_date}'").distinct.order(updated_at: :desc)

    samples = {last_value: nil, count: 0, total_elapsed_sample_time: 0.0}
    cases.each do |a_case|
      check_samples(samples, a_case.updated_at)
      break if samples[:count] >= 4
    end

    if samples[:count] < 4
      flash[:danger] = "Invalid date range chosen - less than 4 days of sample data exist between start date '#{start_date[0,10]}' and end date '#{end_date[0,10]}'"
    else
      Globals.set(:start_date,start_date)
      Globals.set(:end_date,end_date)
    end
    redirect_to root_path
  end

end

class Covid19ChartUpdateChannel < ApplicationCable::Channel
  def subscribed
    stream_from "Covid19ChartUpdateChannel"
    Rails.logger.log(Logger::INFO,"Subscribed to Covid19ChartUpdateChannel!")
    # stream_from "some_channel"
  end

  def unsubscribed
    Rails.logger.log(Logger::INFO,"Unsubscribed from Covid19ChartUpdateChannel!")
    # Any cleanup needed when channel is unsubscribed
  end
end

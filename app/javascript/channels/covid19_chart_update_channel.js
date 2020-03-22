import consumer from "./consumer"

consumer.subscriptions.create("Covid19ChartUpdateChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("Connected to the Covid19ChartUpdateChannel!");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("Disconnected from the Covid19ChartUpdateChannel!");
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("Received data from Covid19ChartUpdateChannel!")

    if ("selected" in data) {
      $('#covid19-chart-container').html(data.selected);
    }
    else if ("global" in data) {
      $('#covid19-info-tile').html(data.global);
    }
    else
    {
      console.log("Data received from Covid19ChartUpdateChannel is unknown")
    }
  }
});

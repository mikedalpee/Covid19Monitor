class ScrapeSession

  MAX_BROWSER_LAUNCH_RETRIES=3
  BROWSER_LAUNCH_RETRY_DELAY=2

  @@user_agents = [
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36",
  # "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0",
  # "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36",
  # "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36 OPR/63.0.3368.107",
  # "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.18362"
  ]

  attr_reader :browser, :min_goto_delay, :max_goto_delay, :headless, :proxy

  def initialize(headless: true)
    @headless = headless
    @user_agent = @@user_agents[rand(0..@@user_agents.size-1)]
    @chromedriver_path = File.join(ENV['HOME'],'.webdrivers','chromedriver')
    @args = ['--no-sandbox', '--ignore-certificate-errors', '--disable-popup-blocking', '--disable-translate', '--enable-crash-reporter',"--user-agent=#{@user_agent}"]
    @browser = nil
    @terminated = false
    if @headless
      @args.push('--headless')
    end
  end

  def open
    (1..MAX_BROWSER_LAUNCH_RETRIES).each do |i|
      return if terminated?
      begin
        Rails.logger.info("Creating browser session with user agent \"#{@user_agent}\"")
        @browser = Watir::Browser.new :chrome, open_timeout: 60,read_timeout: 60, driver_path: @chromedriver_path, options: {args: @args.to_a}
        break
      rescue => e
        if i == MAX_BROWSER_LAUNCH_RETRIES
          raise
        end
      end
      sleep(BROWSER_LAUNCH_RETRY_DELAY)
    end
  end

  def close
    if !@browser.nil?
      begin
        @browser.close
      rescue
      end
    end

    @browser = nil
  end

  def terminate
    @terminated = true
  end

  def terminated?
    @terminated
  end

  MAX_GOTO_URL_ATTEMPTS = 3
  GOTO_URL_RETRY_DELAY = 2

  def goto_url(url)
    (1..MAX_GOTO_URL_ATTEMPTS).each do |i|
      return if terminated?
      exception_message = ""
      begin
        browser.goto(url)

        return if terminated?

        break if !browser.empty_document? && (!block_given? || !yield(self))
      rescue Selenium::WebDriver::Error::UnhandledAlertError => e
        browser.alert.ok
        break
      rescue => e
        exception_message = " (Exception: #{e})"
        # try restart the session
        open
      end
      if i == MAX_GOTO_URL_ATTEMPTS
        raise "Could not navigate to valid page for url '#{url}' after #{MAX_GOTO_URL_ATTEMPTS} attempts#{exception_message}" if i == MAX_GOTO_URL_ATTEMPTS
      end
      sleep(GOTO_URL_RETRY_DELAY)
    end
  end
end

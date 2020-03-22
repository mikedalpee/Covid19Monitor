module ApplicationHelper
  include Covid19ChartHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = "COVID-19 Trends"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def end_with_period(sentence)
    s = sentence
    unless s.blank?
      s.strip!
      unless s.blank?
        if !['!','?','.'].include?(s[-1])
          s += '.'
        end
      end
    end
    s
  end

  def render_flash
    flash_array = []
    flash.each do |type, messages|
      if !messages.nil?
        if messages.is_a?(String)
          flash_array <<
              render(
                  partial: 'shared/flash',
                  locals: { :type => type, :text => end_with_period(messages)}) unless messages.blank?
        elsif messages.respond_to?(:each)
          messages.each do |m|
            flash_array <<
                render(
                    partial: 'shared/flash',
                    locals: { :type => type, :text => end_with_period(m) }) unless m.blank?
          end
        end
      end
    end

    flash_array.join('').html_safe
  end
end

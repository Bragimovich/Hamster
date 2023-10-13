# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize args
    super
    @debug = true if args[:debug]
    @run_id = (args[:run_id].nil?) ? 0 : args[:run_id]
  end

  def get_file_data(response)
    page = Nokogiri::HTML response.body
    links = page.css('a')
    file_name = links[4].values.last[2..]
  end
end

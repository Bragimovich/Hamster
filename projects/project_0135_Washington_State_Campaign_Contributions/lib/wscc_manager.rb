

class WSCCManager

  def initialize(**options)
    if options[:type]
      p options[:type]
      Scraper.new(options[:type])
      ParserNew.new(options[:type])
    elsif options[:update]
      Scraper.new()
      ParserNew.new()
    end
    1
  end

end
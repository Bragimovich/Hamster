class Parser < Hamster::Parser
  def initialize(html)
    @html = Nokogiri::HTML(html)
  end

  def form_data
    {
      '__VIEWSTATE' => @html.at_css('#__VIEWSTATE')['value'],
      '__VIEWSTATEGENERATOR' => @html.at_css('#__VIEWSTATEGENERATOR')['value'],
      '__EVENTVALIDATION' => @html.at_css('#__EVENTVALIDATION')['value']
    }
  end

  def cities
    content = @html.css('script').last.content
    JSON.parse(content.slice(14..-2))
  end
end

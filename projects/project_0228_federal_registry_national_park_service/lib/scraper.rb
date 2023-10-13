# frozen_string_literal: true
class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_main_page(start_date,current_date)
    url = "https://www.nps.gov/solr/?fl=Type,Abstract,Image_URL,Image_Alt_Text,Title,Sites,Series,Date_Released,Organization,PageURL&defType=edismax&fq=-Date_Released:[NOW%20TO%20*]&fq=Category:%22News%22&json.wrf=jQuery1124037520536038033114_1641456095209&rows=38392&wt=json&q=*&sort=Date_Released+desc&start=0&facet=true&facet.mincount=1&facet.limit=-1&facet.sort=count&facet.method=enum&facet.field=Type&facet.field=Sites_Item&fq=Date_Released%3A%5B#{start_date}T00%3A00%3A00Z+TO+#{current_date}T00%3A00%3A00Z%5D&hl=true&hl.fl=text%2C+title&hl.simple.pre=%3Cem%3E&hl.simple.post=%3C%2Fem%3E&hl.snippets=3&_=1641456095213"
    connect_to(url)
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end

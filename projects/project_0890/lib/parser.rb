# frozen_string_literal: true
class Parser < Hamster::Parser
  def initialize
    super
  end

  def xls_file_links(key, response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    links = []
    case key
    when :assessment
      parsed_doc.xpath("//article[@class='file']/p/a").each do |a_tag|
        links << {name: a_tag.text, url: a_tag.xpath("./@href").first.value} if a_tag.text.match(/xlsx/)
      end
    when :assessment_act
      parsed_doc.xpath("//div[@class='field__item']/div/div/p/a").each do |a_tag|
        links << {name: a_tag.text, url: a_tag.xpath("./@href").first.value}
      end
    when :assessment_ap_sat
      parsed_doc.xpath("//div[@class='accordion-body']/div/p/a").each do |a_tag|
        links << {name: a_tag.text, url: a_tag.xpath("./@href").first.value}
      end
    when :finances
      parsed_doc.xpath("//div[@class='accordion-body']/div/table/tbody/tr[2]/td/a").each do |a_tag|
        url = a_tag.xpath("./@href").first.value
        links << {name: url.match(/reporting\/(.+)\/download/)[1], url: url}
      end
    end
    links
  end
end

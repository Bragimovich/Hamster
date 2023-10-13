class IrsNonProfitParser < Hamster::Parser
  def initialize(**page)
    super
    @html  = Nokogiri::HTML(page[:html])               if page[:html]
    @links = @html.css('div.field--name-body ul li a') if page[:html] && page[:type] == :forms
    @json  = JSON.parse(page[:json])                   if page[:json]
  end

  def find_links
    @html.css('p').select { |i| i.text.match?(/Region\s\d:/) }.map { |i| i.at('a')['href'] }
  end

  def parse_pub_78
    tag_a = @links.find { |a| a.text.match?(/Tax-Deductible Charitable Contributions/) }
    date  = Date.parse(tag_a.parent.parent.next_element.text[/Last Updated: (\w+ \d+, \d+)/, 1])
    { link: tag_a['href'], date: date }
  end

  def parse_990_n
    tag_a = @links.find { |a| a.text.match?(/Form 990-N Data/) }
    date  = Date.parse(tag_a.parent.parent.next_element.text[/Latest data posting:.(\w+ \d+, \d+)/, 1])
    { link: tag_a['href'], date: date }
  end

  def parse_auto_rev_list
    tag_a = @links.find { |a| a.text.match?(/Exemption List/) }
    date  = Date.parse(tag_a.parent.parent.next_element.text.match(/\w+\s\d{1,2},\s\d{4}/).to_s)
    { link: tag_a['href'], date: date }
  end

  def parse_990s
    tag_a = @links.find { |a| a.text.match?(/Form 990 Series/) }
    date  = Date.parse(tag_a.parent.parent.next_element.text.match(/\w+\s\d{1,2},\s\d{4}/).to_s)
    { link: "https://www.irs.gov#{tag_a['href']}", date: date }
  end

  def parse_years(last_date)
    @html.css('.accordion-list')[-1].css('.collapsible-item .collapsible-item-body p a')
         .map { |a| "https://www.irs.gov#{a['href']}" }
         .select { |link| link.match(/\d{4}$/).to_s.to_i >= last_date.year }
  end

  def parse_months_urls
    @html.css('.collapsible-item-body p a').map { |month| month[:href] }
  end

  def parse_orgs
    @json['items'].map do |i|
      org = {}
      org[:ein]             = i["ein"].strip
      org[:org_name]        = i["name"].strip
      org[:city]            = i["city"]&.strip
      org[:state]           = i["state"]&.strip
      org[:country]         = i["country"].strip
      org[:org_name_parens] = i["dba"]&.strip

      md5                   = MD5Hash.new(columns: org.keys)
      md5_hash              = md5.generate(org)
      org[:md5_hash]        = md5_hash

      org
    end
  end
end

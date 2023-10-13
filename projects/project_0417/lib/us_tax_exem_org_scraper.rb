require_relative '../lib/us_tax_exem_org_parser'
require_relative '../lib/us_tax_exem_org_keeper'
class USTaxExemOrgScraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count_new    = 0
    @keeper       = keeper
  end

  attr_reader :count_new

  def scrape_org
    page   = 1
    run_id = keeper.run_id
    loop do
      url = "https://nonprofitlight.com/page/#{page}"
      body   = get_page_body(url)
      parser = USTaxExemOrgParser.new(html: body)
      orgs   = parser.parse_orgs
      break unless orgs

      orgs.each_with_index do |org, idx|
        puts "Page #{page} -- link №#{idx}".green
        unless org[:link].match?(%r{/[a-zA-Z]{2}/})
          keeper.save_broken_link(org)
          next
        end
        body_org = get_page_body(org[:link])
        parser   = USTaxExemOrgParser.new(html: body_org)
        xml_link = parser.parse_xml_link
        next if xml_link.nil?

        md5 = MD5Hash.new(columns: %i[url])
        md5.generate({ url: xml_link })
        name = md5.hash
        links_org = "#{xml_link}\n#{org[:link]}"
        peon.put(file: name, content: links_org, subfolder: "#{run_id}_url")
        body_xml = get_page_body(xml_link)
        peon.put(file: name, content: body_xml, subfolder: "#{run_id}_xml")
      end
      page += 1
    end
  rescue StandardError => e
    puts "#{e} | #{e.full_message}"
    Hamster.report(to: 'Eldar Eminov', message: "Page #{page} -- #{e}", use: :both)
  end

  private

  attr_reader :keeper

  def get_page_body(link)
    filter = @proxy_filter
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: filter, ssl_verify: false)
  end

  def connect_to(*arguments)
    response = nil
    10.times do
      response = super(*arguments)
      break if response&.status && [200, 304].include?(response.status)
    end
    response&.body
  end
end

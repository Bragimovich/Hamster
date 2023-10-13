class Scraper < Hamster::Scraper
  def initialize(**option)
    super
    @proxy_filter  = ProxyFilter.new(duration: 1.hours, touches: 500)
    @html          = Nokogiri::HTML(option[:html])
    @teg_phrase    = option[:teg_phrase]
    @url           = option[:url]
    @url_migration = option[:url_migration]
  end
  # Comma separated value file => Search phrase for IRSGrossMigration
  # State-to-State Inflow      => Search phrase for IRSStateInflow
  # State-to-State Outflow     => Search phrase for IRSStateOutflow
  YEAR_FIRST = 2011
  def scrape_link(name_csv)
    come_in = @html.css('div.field--name-body p a').size - 1
      [*0..come_in].each do |num_teg|
        if @html.css('div.field--name-body p a')[num_teg].text == name_csv
          return @html.css('div.field--name-body p a')[num_teg]['href']
        end
      end
  end
  def return_link
    site           = connect_to(@url_migration, proxy_filter: @proxy_filter, ssl_verify: false)
    site_body      = Nokogiri::HTML(site.body)
    migration_data = site_body.css('div.collapsible-item-body.panel-body a')[0..8].reverse
    migration_data.map { |year| @url + year['href'] }
  end
  def scrape(links)
    years_start = YEAR_FIRST
    links.each do |link|
      years_range = years_start.to_s + '-' + (years_start + 1).to_s
      response    = connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false)
      scrap_teg   = Scraper.new(html: response.body)
      @teg_phrase.each do |table_name|
        csv_url = scrap_teg.scrape_link(table_name)
        csv     = connect_to(csv_url, proxy_filter: @proxy_filter, ssl_verify: false).body
        peon.put(file: "#{years_range}.#{table_name.gsub(/[' '-]/, '_')}.csv", content: csv, subfolder: "csv")
      end
      years_start += 1
    end
  rescue => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'Halid Ibragimov', message: e.message + ' /In #533', use: :both)
  end
end

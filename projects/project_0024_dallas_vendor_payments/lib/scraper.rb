# frozen_string_literal: true

require_relative '../models/irs_nonprofit_runs'
require_relative '../models/irs_nonprofit_temp_forms'
require_relative '../models/irs_nonprofit_forms_info'

require_relative '../lib/validate_error.rb'

require 'zip'

class Scraper < Hamster::Harvester
  HEADERS = {
      accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      accept_language:           'en-US,en;q=0.9,ru;q=0.8,ru-RU;q=0.7,uk;q=0.6,uz;q=0.5',
      cache_control:             'max-age=0',
      connection:                'keep-alive',
      host:                      'apps.irs.gov',
      sec_fetch_dest:            'document',
      sec_fetch_mode:            'navigate',
      sec_fetch_site:            'same-origin',
      sec_fetch_user:            '?1',
      upgrade_insecure_requests: '1',
      user_agent:                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36'
  }

  def initialize
    super
    @proxy_filter = ProxyFilter.new

    @full_scrape   = commands[:full_scrape]
    @orgs_scrape   = commands[:orgs_only]       || @full_scrape
    @all_forms     = commands[:all_forms]
    @pub_78        = commands[:pub_78]          || @all_forms || @full_scrape
    @auto_rev_list = commands[:auto_rev_list]   || @all_forms || @full_scrape
    @form_990n     = commands[:form_990n]       || @all_forms || @full_scrape
    @form_990s     = commands[:form_990_series] || @all_forms || @full_scrape

    if @orgs_scrape
      @run_id = nil
      set_run_id

      # Can be 'new', 'from [number of orgs_list_page]'(start norm scraping from page given), 'test [number of orgs_list_page]' (scrape only page given)
      @progress = commands[:progress] || 'new'

      @per_list_page = [25, 50, 200, 250].include?(commands[:per_list_page]) ? commands[:per_list_page] : raise(ValidateError, 'Incorrect `--per_list_page`, should be 25, 50, 200 or 250!')
    elsif @pub_78 || @auto_rev_list || @form_990n || @form_990s
      @run_id = commands[:run_id] || raise(ValidateError, 'No `run_id` given for forms-only scrape.')

      @pub_78 || @auto_rev_list || @form_990n || @form_990s
      @forms_download_page = Nokogiri::HTML.parse(connect_to(url: 'https://www.irs.gov/charities-non-profits/tax-exempt-organization-search-bulk-data-downloads').body)
    end

    @current_page = nil
    @list_page_i = 0
    @next_list_page = true

    @proxy = PaidProxy.all
  end

  def main
    if @run_id

      p "run_id = #{@run_id}"

      @_peon_.throw_trash(10)

      p 'trash deleted'

      scrape_pub_78          if @pub_78
      scrape_auto_rev_list   if @auto_rev_list
      scrape_form_990n       if @form_990n
      scrape_form_990s       if @form_990s

      case @progress
      when 'new'
        scrape_orgs_links
      when /\Afrom (\d+), to (\d+)\z/
        scrape_orgs_links(start: $1.to_i, stop: $2.to_i)
      when /\Afrom (\d+)\z/
        scrape_orgs_links(start: $1.to_i)
      when /\Atest (\d+)\z/
        scrape_orgs_links(start: $1.to_i, stop: $1)
      else
        raise(ValidateError, 'Incorrect `--progress` argument, should be `new`, `from [N]` or `test [N]`')
      end
    end

  rescue ValidateError => e
    p e.message
  rescue Interrupt => e
    p e.message
    IrsNonprofitRuns.update(@run_id, {status: 'pause'}) if @run_id
  rescue => e
    p e.backtrace
    p e.message
    IrsNonprofitRuns.update(@run_id, {status: 'error'}) if @run_id
  else
    IrsNonprofitRuns.update(@run_id, {status: 'scraped'}) if @run_id && !(@progress =~ /\Atest/ || @progress =~ /\Afrom (\d+), to (\d+)\z/)
  end

  private

  def scrape_orgs_links (start: nil, stop: nil)
    @list_page_i = start if start
    while @next_list_page && (stop ? @list_page_i <= stop.to_i : true)
      if rand(1..20) == 1
        @proxy = PaidProxy.all
        sleep(rand(21.3..53.2))
      end

      @current_page = get_list_page(@list_page_i)
      @current_page = cut_html

      p @_peon_.put(file: "0000000#{@list_page_i}.html"[-13..-1], content: @current_page.to_html, subfolder: "orgs_list_pages/#{(@list_page_i / 1000.0).floor*1000}_#{((@list_page_i + 1)/1000.0).ceil*1000 - 1}")

      check_next_list_page

      sleep(rand(0.7..5.4))

      @list_page_i += 1
    end

  end

  def get_list_page(page)
    connect_to(url: "https://apps.irs.gov/app/eos/allSearch?page=#{page}&size=#{@per_list_page}&sort=ein%2Casc",proxy: @proxy , headers: HEADERS)
  end

  def cut_html
    selector = '.row.search-results-row>.col-xs-12.col-md-9'
    Nokogiri::HTML.parse(@current_page.body).css(selector)
  end

  def check_next_list_page
    @next_list_page = @current_page.css('.top-of-search-header strong').map{|s| s.text[/\d+\z/] }.uniq.size == 2
  end

  def connect_to(url:, headers: {}, proxy: nil, cookies: nil)
    begin
      response = Hamster.connect_to(url, headers: headers, proxy: proxy, cookies: cookies, proxy_filter: @proxy_filter) {|resp| !resp.headers[:content_type]&.match?(%r{text|html|json|zip}) }

      reporting_request(response)

      if [301, 302].include?(response.status)
        pause = 100 + rand(500)
        puts "Restart connection after #{pause} seconds."
        sleep(pause)
      end
      sleep(7 + rand(5))
    end until response.status == 200
    response
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end

  def set_run_id
    run = IrsNonprofitRuns.all.to_a.last
    if commands[:run_id] == 'force' && run && run[:status] != 'finished'
      @run_id = run[:id]
      IrsNonprofitRuns.update(@run_id, {status: 'processing'})
    elsif commands[:run_id] == 'force' && run && run[:status] == 'finished'
      @run_id = IrsNonprofitRuns.create({})[:id]
    elsif run && run[:status] == 'scraped'
      raise(ValidateError, "Scraping has already been scraped, but not fully parsed yet.")
    else
      raise(ValidateError, "Scraping is already running with run_id = #{run[:id]}") if run && run[:status] == 'processing'
      if run && %w(pause error).include?(run[:status])
        @run_id = run[:id]
        IrsNonprofitRuns.update(@run_id, {status: 'processing'})
      else
        @run_id = IrsNonprofitRuns.create({})[:id]
      end
    end
  end

  def scrape_pub_78


    last_updated = IrsNonprofitFormsInfo.last_updated('Publication 78 Data') unless @pub_78 == 'force'

    new_date = Date.parse(@forms_download_page.css('a[href="https://apps.irs.gov/pub/epostcard/data-download-pub78.zip"]').first.parent.next_element.text[/Last Updated: (\w+ \d+, \d+)/, 1]).to_s unless @pub_78 == 'force'

    if @pub_78 == 'force' || last_updated != new_date
      IrsNonprofitFormsInfo.set_last_updated('Publication 78 Data', new_date) unless @pub_78 == 'force'
      p IrsNonprofitFormsInfo.last_updated('Publication 78 Data')

      IrsNonprofitRuns.connection.create_table(:irs_nonprofit_pub_78_temp, id: false, if_not_exists: true) do |t|
        t.string :ein, limit: 9
        t.string :org_name, limit: 500
        t.string :city, limit: 100
        t.string :state, limit: 2
        t.string :country, limit: 20
        t.string :deductibility_code, limit: 50
        t.index  :ein
      end

      download_zip("https://apps.irs.gov/pub/epostcard/data-download-pub78.zip", "pub78.txt")

      path = @_peon_.move_and_unzip_temp(file: "pub78.txt", from: "run_#{@run_id}/forms/pub78/", to: "run_#{@run_id}/forms/pub78/")

      query = "LOAD DATA LOCAL INFILE '#{path}'
                 IGNORE
                 INTO TABLE irs_nonprofit_pub_78_temp
                 FIELDS
                   TERMINATED BY '|';"

      IrsNonprofitTempForms.connection.execute(query)


      @_peon_.throw_temps
    end

  end

  def scrape_auto_rev_list

    last_updated = IrsNonprofitFormsInfo.last_updated('Automatic Revocation of Exemption List') unless @auto_rev_list == 'force'

    new_date = Date.parse(@forms_download_page.css('a[href="https://apps.irs.gov/pub/epostcard/data-download-revocation.zip"]').first.parent.next_element.text[/Last Updated: (\w+ \d+, \d+)/, 1]).to_s unless @auto_rev_list == 'force'

    if @auto_rev_list == 'force' || last_updated != new_date
      IrsNonprofitFormsInfo.set_last_updated('Automatic Revocation of Exemption List', new_date) unless @auto_rev_list == 'force'
      p IrsNonprofitFormsInfo.last_updated('Automatic Revocation of Exemption List')

      IrsNonprofitRuns.connection.create_table(:irs_nonprofit_auto_rev_list_temp, if_not_exists: true) do |t|
        t.string :ein, limit: 9
        t.string :org_name, limit: 255
        t.string :parens, limit: 255
        t.string :street, limit: 255
        t.string :city, limit: 100
        t.string :state, limit: 2
        t.string :zip, limit: 10
        t.string :country, limit: 20
        t.string :exemption_type, limit: 10
        t.string :revocation_date, limit: 20
        t.string :revocation_posting_date, limit: 20
        t.string :exemption_reinstatement_date, limit: 20
        t.index :ein
      end

      download_zip("https://apps.irs.gov/pub/epostcard/data-download-revocation.zip", "revocation.txt")

      path = @_peon_.move_and_unzip_temp(file: "revocation.txt", from: "run_#{@run_id}/forms/revocation/", to: "run_#{@run_id}/forms/revocation/")

      query = "LOAD DATA LOCAL INFILE '#{path}'
                 IGNORE
                 INTO TABLE irs_nonprofit_auto_rev_list_temp
                 FIELDS
                   TERMINATED BY '|'
                 (ein,org_name,parens,street,city,state,zip,country,exemption_type,revocation_date,revocation_posting_date,exemption_reinstatement_date);"

      IrsNonprofitTempForms.connection.execute(query)


      @_peon_.throw_temps
    end

  end

  def scrape_form_990n

    last_updated = IrsNonprofitFormsInfo.last_updated('Form 990-N (e-Postcard)') unless @form_990n == 'force'

    new_date = Date.parse(@forms_download_page.css('a[href="https://apps.irs.gov/pub/epostcard/data-download-epostcard.zip"]').first.parent.next_element.text[/Last Updated: (\w+ \d+, \d+)/, 1]).to_s unless @form_990n == 'force'

    if @form_990n == 'force' || last_updated != new_date
      IrsNonprofitFormsInfo.set_last_updated('Form 990-N (e-Postcard)', new_date) unless @form_990n == 'force'
      p IrsNonprofitFormsInfo.last_updated('Form 990-N (e-Postcard)')

      IrsNonprofitRuns.connection.create_table(:irs_nonprofit_990n_temp, id: false, if_not_exists: true) do |t|
        t.string :ein, limit: 9
        t.string :tax_period_year, limit: 4
        t.string :org_name, limit: 255
        t.string :t_col, limit: 10
        t.string :f_col, limit: 10
        t.string :tax_period_start, limit: 10
        t.string :tax_period_end, limit: 10
        t.string :website_url, limit: 300
        t.string :principal_officer_name, limit: 200
        t.string :principal_officer_street, limit: 200
        t.string :unknown_1, limit: 200
        t.string :principal_officer_city, limit: 200
        t.string :unknown_2, limit: 200
        t.string :principal_officer_state, limit: 200
        t.string :principal_officer_zip, limit: 200
        t.string :principal_officer_country, limit: 200
        t.string :mailing_address_street, limit: 200
        t.string :unknown_3, limit: 200
        t.string :mailing_address_city, limit: 200
        t.string :unknown_4, limit: 200
        t.string :mailing_address_state, limit: 200
        t.string :mailing_address_zip, limit: 200
        t.string :mailing_address_country, limit: 200
        t.string :org_parens, limit: 1000
        t.string :unknown_5, limit: 255
        t.string :unknown_6, limit: 255

        t.index :ein
      end

      download_zip("https://apps.irs.gov/pub/epostcard/data-download-epostcard.zip", "990n.txt")

      path = @_peon_.move_and_unzip_temp(file: "990n.txt", from: "run_#{@run_id}/forms/990n/", to: "run_#{@run_id}/forms/990n/")

      query = "LOAD DATA LOCAL INFILE '#{path}'
                 IGNORE
                 INTO TABLE irs_nonprofit_990n_temp
                 FIELDS
                   TERMINATED BY '|';"

      IrsNonprofitTempForms.connection.execute(query)

      @_peon_.throw_temps
    end

  end

  def scrape_form_990s
    last_updated = ''
    link = ''

    form_page = Nokogiri::HTML.parse(connect_to(url: 'https://www.irs.gov/charities-non-profits/form-990-series-downloads').body)

    if @form_990s == 'force' || @form_990s =~ /https:\/\/www\.irs\.gov\/pub\/irs-tege\/\w+-\d{4}-990-index.csv/
      if @form_990s == 'force'
        link = form_page.css('.collapsible-item.panel.panel-default').first.css('.collapsible-item-body.panel-body p a').last['href']
      else
        link = @form_990s
      end
    else
      last_updated = IrsNonprofitFormsInfo.last_updated('Form 990')
      link = form_page.css('.collapsible-item.panel.panel-default').first.css('.collapsible-item-body.panel-body p a').last['href']
    end

    p link

    new_date = Date.parse(@forms_download_page.css('p a[href="/charities-non-profits/form-990-series-downloads"]').first.parent.next_element.text[/Last Updated: (\w+ \d+, \d+)/, 1]).to_s

    if @form_990n == 'force' || last_updated != new_date
      if last_updated != new_date
        IrsNonprofitFormsInfo.set_last_updated('Form 990', new_date)
        IrsNonprofitFormsInfo.set_last_updated('Form 990-EZ', new_date)
        IrsNonprofitFormsInfo.set_last_updated('Form 990-PF', new_date)
        IrsNonprofitFormsInfo.set_last_updated('Form 990-T', new_date)
      end

      p IrsNonprofitFormsInfo.last_updated('Form 990-N (e-Postcard)')

      IrsNonprofitRuns.connection.create_table(:irs_nonprofit_990s_temp, id: false, if_not_exists: true) do |t|
        t.string :return_link_id, limit: 8
        t.string :filing_type, limit: 1
        t.string :ein, limit: 9
        t.string :tax_period, limit: 6
        t.string :return_fill_date, limit: 10
        t.string :org_name, limit: 300
        t.string :return_type, limit: 10
        t.string :unknown_1, limit: 100
        t.string :unknown_2, limit: 100

        t.index :ein
      end

      file_name = "990s_#{link[/https:\/\/www\.irs\.gov\/pub\/irs-tege\/(\w+-\d{4})-990-index.csv/, 1]}.csv"

      p @_peon_.put(file: file_name, content: connect_to(url: link).body, subfolder: "run_#{@run_id}/forms/990s/")

      path = @_peon_.move_and_unzip_temp(file: file_name, from: "run_#{@run_id}/forms/990s/", to: "run_#{@run_id}/forms/990s/")

      query = "LOAD DATA LOCAL INFILE '#{path}'
                 IGNORE
                 INTO TABLE irs_nonprofit_990s_temp
                 FIELDS
                   TERMINATED BY ',';"

      IrsNonprofitTempForms.connection.execute(query)

      @_peon_.throw_temps
    end

  end

  def download_zip(link, file_name)
    input = connect_to(url: link, headers: HEADERS).body
    Zip::File.open_buffer(input) do |zip_file|
      zip_file.each do |entry|
        p @_peon_.put(file: file_name, content: entry.get_input_stream.read, subfolder: "run_#{@run_id}/forms/#{file_name[/\A\w+/]}/")
      end
    end
  end
end

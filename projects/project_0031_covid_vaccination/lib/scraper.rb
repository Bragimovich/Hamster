# frozen_string_literal: true

require_relative '../models/runs'
require_relative '../lib/validate_error.rb'

class Scraper < Hamster::Harvester

  def initialize
    super


    @link = 'https://www.medalerts.org/vaersdb/findfield.php?EVENTS=on&PAGENO=1&PERPAGE=1000&ESORT=&REVERSESORT=&VAX=(COVID19)&DIED=Yes'
    @data_as_of = ''

    @run_id = %w(force f auto a).include?(commands[:run_id]) ? commands[:run_id] : raise(ValidateError, 'Incorrect `run_id`, could be only "force"("f") or "auto"("a").')

    @proxy = PaidProxy.all
  end

  def main
    Hamster.report(to: 'G01PBNVPM4K', message: 'Hello world!')
    @list_page = Nokogiri::HTML.parse(connect_to(url: @link, proxy: @proxy).body)

    @data_as_of = Date.strptime(@list_page.css('.totalwid h2').first.text[/\d{1,2}\/\d{1,2}\/\d{4}/], "%m/%d/%Y").to_s
    total_cases = @list_page.css('.totalwid h1').first.text[/Found (\d+)/, 1]

    p @data_as_of, total_cases

    set_run_id

    if @run_id

    else
      p "Hasn't changed since #{@data_as_of}"
    end
    # @data_as_of = Date.parse(@link[/as of (.+)\.xlsx\z/, 1]).to_s
    #
    # set_run_id
    #
    # xlsx = connect_to(url: @link.gsub(' ', '%20'), proxy: @proxy).body
    #
    # @_peon_.put(file: 'data.xlsx', content: xlsx, subfolder: "run_#{@run_id}/")
    # p path = @_peon_.move_and_unzip_temp(file: 'data.xlsx', from: "run_#{@run_id}/", to: "run_#{@run_id}/")

  rescue ValidateError => e
    p e.message
  rescue Interrupt => e
    p e.message
    Runs.pause(@run_id)
  rescue => e
    p e.backtrace
    p e.message
    Runs.error(@run_id)
  else
    Runs.scraped(@run_id)
  end

  private

  def scrape_list (per_page = 1000)
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
      response = Hamster.connect_to(url, headers: headers, proxy: proxy, cookies: cookies) {|resp| !resp.headers[:content_type]&.match?(%r{text|html|json|sheet}) }

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
    run = Runs.last_run

    p !%w(force f).include?(@run_id)
    p !%w(force f).include?(@run_id) && run && run[:data_as_of] != @data_as_of
    p run.nil?
    if (!%w(force f).include?(@run_id) && run && run[:data_as_of] != @data_as_of) || run.nil?
      if %w(force f).include?(@run_id) && run && run[:status] != 'finished'
        @run_id = run[:id]
        Runs.processing(@run_id)
      elsif commands[:run_id] == 'force' && run && run[:status] == 'finished'
        @run_id = Runs.create({data_as_of: @data_as_of})[:id]
      elsif run && run[:status] == 'scraped'
        raise(ValidateError, "Scraping has already been scraped, but not fully parsed yet.")
      else
        raise(ValidateError, "Scraping is already running with run_id = #{run[:id]}") if run && run[:status] == 'processing'
        if run && %w(pause error).include?(run[:status])
          @run_id = run[:id]
          Runs.processing(@run_id)
        else
          @run_id = Runs.create({data_as_of: @data_as_of})[:id]
        end
      end
    else
      @run_id = nil
    end
  end

end

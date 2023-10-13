# frozen_string_literal: true

require_relative '../models/greenville_case_info'


class Scraper < Hamster::Scraper

  def initialize(scrape_year, scrape_month=1, scrape_day=1, general=false, update=0)
    super
    @list_cases_done = Array.new()
    @scrape_year = scrape_year
    @error = 0

    @scrape_month = scrape_month-1

    #@path_to_folder = storehouse
    @peon = Peon.new(storehouse)

    @url_start = 'https://www2.greenvillecounty.org/scjd/publicindex/?AspxAutoDetectCookieSupport=0'

    @dasher = Dasher.new(using: :hammer, headless:true, pc:1)
    @how_scrape = general

    get_start(scrape_year, scrape_month, scrape_day, update)

    @dasher.close
  end

  def get_browser
    if @browser
      @dasher.close
    end

    @dasher = Dasher.new(using: :hammer, pc:1,headless:true)
    @dasher.get(@url_start)
    sleep 10
    @browser = @dasher.connection

  end

  def get_case_id_in_db(month)
    old_case_numbers =Array.new()
    date_from = "#{@scrape_year}-#{month.to_s.rjust(2, '0')}-01"
    if month<12
      date_to = "#{@scrape_year}-#{(month+1).to_s.rjust(2, '0')}-01"
    elsif month==12
      date_to = "#{@scrape_year+1}-01-01"
    end
    GreenvilleCaseInfo.where("court_id=32 AND case_filed_date>='#{date_from}' AND case_filed_date<'#{date_to}'").select(:case_id).each do |line|
      old_case_numbers.push(line.case_id)
    end
    old_case_numbers
  end

  def auth_to_site
    if @browser
      if !@browser.client.nil?
        if @browser.pages.length>1
          #@browser.pages[-1].close
        end
      end
    end
    #url_start = 'https://www2.greenvillecounty.org/scjd/publicindex/?AspxAutoDetectCookieSupport=0'
    #@browser = Hamster::Scraper::Dasher.new(url_start, using: :hammer, hammer_opts: {headless: false}).smash

    @dasher.get(@url_start)
    @browser = @dasher.connection
    sleep 2.5
    #sleep 10
    @browser.css("input[id='ContentPlaceHolder1_ButtonAccept']")[0].click
    sleep 2
    #@browser.css("input[id='ContentPlaceHolder1_ButtonAccept']")[0].click
    @link_search = @browser.current_url
    #@browser.screenshot(path: "/Users/Magusch/HarvestStorehouse/project_0067/store/page_auth.png")
    @browser
  end

  def get_start(scrape_year, scrape_month, scrape_day, update)
    list_cases_month = Array.new()
    scrape_date = Date.new(scrape_year, scrape_month, scrape_day)
    if scrape_year==Date.today.year
      last_date = Date.today
    else
      last_date = Date.new(scrape_year+1, 1, 1)
    end


    #scrape_date = Date.new(2021,5,20)
    load_error = 0
    while scrape_date!=last_date
      date_str = "#{scrape_date.month.to_s.rjust(2, '0')}/#{scrape_date.day.to_s.rjust(2, '0')}/#{scrape_date.year}"
      @date_str = date_str
      logger.info @date_str

      if scrape_date.month!=@scrape_month and update==0
        @list_cases_done = @list_cases_done - list_cases_month
        list_cases_month = get_case_id_in_db(scrape_date.month)
        @peon.give_list(subfolder:"#{scrape_year}/#{scrape_date.month}").each { |f|  list_cases_month.push(f.split('.gz')[0]) if f.include?('.gz')}

        @list_cases_done.concat list_cases_month
        @scrape_month = scrape_date.month
      elsif scrape_date.month!=@scrape_month and update>0
        @list_cases_done = @list_cases_done - list_cases_month
        @peon.give_list(subfolder:"#{scrape_year}/#{scrape_date.month}/update").each { |f|  list_cases_month.push(f.split('.gz')[0]) if f.include?('.gz')}
        @list_cases_done.concat list_cases_month
        @scrape_month = scrape_date.month
      end


      page = auth_to_site
      get_page_cases(browser=page, scrape_date_str=date_str, update=update)
      sleep 4
      #@browser.screenshot(path:  @path_to_folder + "page_search_.png")
      if !page.at_css("div[id='ContentPlaceHolder1_PanelSearchResults']") and !page.css("div[id='ContentPlaceHolder1_PanelMessages'][style='display: none;']")[0]
        load_error+=1
        redo if load_error<3
        scrape_date+=1
        next
      end
      if @how_scrape
        @logger.debug 'general'
        statement = true
      else
        @logger.debug 'all'
        statement = page.css("div[id='ContentPlaceHolder1_PanelMessages'][style='display: none;']")[0]
      end

      if statement
        @court_agency = nil
        redo if !page.css("div[id='ContentPlaceHolder1_PanelSearchResults']")[0]
        cycle_cases(page, scrape_date_str=date_str, update=update)

      else
        sleep 1
        get_court_agencies(page).each do |court_agency|
          error_count = 0 if @court_agency!=court_agency
          @court_agency = court_agency
          #@browser.screenshot(path:  @path_to_folder + "page1_#{court_agency}.png")
          sleep 1.5

          begin
            page.css("select[id='ContentPlaceHolder1_DropDownListAgencies']")[0].focus.click.type(@court_agency, :Enter)
            sleep 1.5
            restart_num = 0
            while defined? !page.css("div[id='ContentPlaceHolder1_PanelSearchFields']")
              if restart_num == 2
                page = restart(scrape_date_str=date_str, update=update)
                sleep 2
                break
              end
              sleep 1
              restart_num +=1
            end

            if !page.css("div[id='ContentPlaceHolder1_PanelMessages'][style='display: none;']")[0] and page.css("input[id='ContentPlaceHolder1_ButtonCancel']")[0]
              #@browser.screenshot(path:  @path_to_folder + "FFFF.png")
              page.css("input[id='ContentPlaceHolder1_ButtonCancel']")[0].focus.click
              next
            elsif defined? @browser
              if !@browser.client.nil?
                page = restart(scrape_date_str, update)
              end
            end
            sleep 2
            if page.css("div[id='ContentPlaceHolder1_PanelSearchResults']")[0]
              cycle_cases(page, scrape_date_str=date_str, update=update)
            else
              page = restart(scrape_date_str, update)
              redo
            end
          rescue => e
            @logger.error e
            error_count+=1
            if @browser.client.nil? or error_count>5
              logger.error 'browser - nil'
              get_browser
            end
            page = restart(scrape_date_str, update)
            redo
          end
          # if browser.body is nill -> answer = 1 -> restart
        end
      end
      scrape_date+=1
      if defined? @browser
        if !@browser.client.nil?
          if @browser.pages.length>1
            @browser.pages[-1].close
          end
        end
      end
    end
  end

  def restart(scrape_date_str, update=0)
    page = auth_to_site
    get_page_cases(page, scrape_date_str=scrape_date_str, update=update)
  end


  def cycle_cases(browser, scrape_date_str, update=0)
    browser = check_browser
    sleep_time = 2
    list_cases = get_list_cases browser.body
    list_cases.each_index do |i|
      next if @list_cases_done.include?(list_cases[i][:case_id])
      next if !list_cases[i][:status].match('Criminal').nil?
      answer = get_case_and_return(browser, i, list_cases[i][:case_id], update=update)
      sleep 2
      if !browser.css("span[id='ContentPlaceHolder1_LabelErrorMessage'][style='display: none;']") or browser.network.status>400
        @logger.error "error: #{@error}"
        browser = auth_to_site
        exit 1 if @error>15
        @error+=1
        sleep sleep_time
        sleep_time +=1
      end
      browser = get_page_cases(browser, scrape_date_str=scrape_date_str, update=update)
      redo if answer==0
    end
  end


  def get_case_and_return(browser, number, case_id, update=0)
    browser.mouse.scroll_to(0, number*30)
    browser.go_to("javascript:__doPostBack('ctl00$ContentPlaceHolder1$SearchResults','openDetails$#{number}')")
    sleep 1
    #browser = check_browser
    begin
      return 0 if browser.network.status>400 or !browser.at_css("div[id='ContentPlaceHolder1_TabContainerCaseDetails']") or !browser.css("table[class='detailsSection']")[0]
    rescue
      return 0
    end
    subfolder = "#{@scrape_year}/#{@scrape_month}/"
    subfolder+="update/" if update==1
    @peon.put content: browser.body, file: "#{case_id}", subfolder: subfolder
    @logger.debug "case_id: #{case_id}"
    @list_cases_done.push(case_id)
    browser.go_to(@link_search)
    #@browser.screenshot(path:  @path_to_folder + "page_search_#{number}.png")
    browser
  end

  def check_browser
    if defined? @browser
      if !@browser.client.nil?
        if @browser.pages.length>1
          return @browser.pages[-1]
        else
          page = restart(@date_str)
        end
      else
        @browser = Hamster::Scraper::Dasher.new(using: :hammer, headless: true ).connect
        page = restart(@date_str)
      end
    end
    @browser.pages[-1]
  end

  def get_page_cases(browser, scrape_date_str='06/01/2021', update = 0) #todo: parametrs
    case update
    when 0
      data_type="Case Filed "
    when 1
      data_type="Disposed"
    when 2
      data_type="Actions Filed"
    end
    begin
      sleep 0.4
      browser.at_css("select[id='ContentPlaceHolder1_DropDownListDateFilter']").focus.click.type(data_type).click
      sleep 0.1
      browser.at_css("input[id='ContentPlaceHolder1_TextBoxDateFrom']").focus.type(scrape_date_str)
      browser.at_css("input[id='ContentPlaceHolder1_TextBoxDateTo']").focus.type(scrape_date_str)
      #@browser.screenshot(path: @path_to_folder + 'search_page1.png')
      sleep 0.4
      if @court_agency!=nil
        browser.at_css("select[id='ContentPlaceHolder1_DropDownListAgencies']").focus.click.type(@court_agency, :Enter)
      else
        browser.at_css("input[id='ContentPlaceHolder1_ButtonSearch'").focus.click
      end
      sleep 1.2
    rescue => e
      @logger.error e
      browser = auth_to_site
      retry
    end
    browser
  end


  def get_court_agencies(browser=page)
    browser.css("input[id='ContentPlaceHolder1_ButtonCancel']")[0].focus.click
    court_agencies = Array.new()

    doc = Nokogiri::HTML(browser.body)
    doc.at_css("select[id='ContentPlaceHolder1_DropDownListAgencies']").css('option')[1..].each {|agency| court_agencies.push(agency.content)}
    court_agencies
  end


  def get_list_cases(html_page)
    doc = Nokogiri::HTML(html_page)
    cases_array = Array.new()
    doc.at_css("div[id='ContentPlaceHolder1_PanelSearchResults']").css('tr')[1..].each do |line|
      next if line.nil?
      list = line.css('td')
      #cases_array.push({:name => list[0].content, :party_type => list[1].content, :case_id => list[2].content})
      begin
        cases_array.push({:case_id => list[2].content, :status=>list[6].content})
      rescue
        next
      end
    end
    cases_array
  end
end
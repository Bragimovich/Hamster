# frozen_string_literal: true

class ScraperWF < Hamster::Scraper

  def initialize(crime='current')
    @url = 'http://inmates.bluhorse.com/default.aspx?ID=WCCF#'
    @crime = crime
    @restart = 0
    @list_name =
      if crime=='current'
        '#inmateList'
      else
        '#lstPastInmate'
      end
  end

  def main_page
    @dasher.close if !@dasher.nil?
    @restart = 0
    @dasher = Dasher.new(:using=>:hammer, pc:1) #,headless: false
    @dasher.get(@url)
  end

  def body
    @dasher.connection.body
  end


  def number_of_arrestees(letter='')
    error_count = 0
    begin
      main_page if @dasher.nil? or @restart>9
      get_all_inmates(letter) if @crime=='all'
    rescue => e
      p "Error counter: #{error_count} for error: #{e}"
      error_count+=1
      @restart=10
      raise ("Error ! #{e} ! With letter #{letter}") if error_count>3
      retry
    end
    @restart += 1
    @dasher.connection.evaluate("$('#{@list_name} li').size();")
  end


  def person_page(number)
    main_page if @restart>10 or @dasher.nil?
    browser = @dasher.connection
    browser.evaluate("$('#{@list_name} li')[#{number}].click();")
    sleep 3
    browser.body
  end


  def get_all_inmates(letter)
    browser = @dasher.connection
    browser.at_css(".inimate").click
    sleep(7)
    browser.at_css("input#txtPLastName").focus.click.type(letter)
    browser.at_css('button#btnPSearch').focus.click
    sleep(5)
  end


end

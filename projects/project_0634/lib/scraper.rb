require_relative './parser'

class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
    @hammer = Dasher.new(using: :hammer,  headless: true)

    @browser = @hammer.connect
    @peon = Peon.new(storehouse)
    @parser = Parser.new

    @domain = 'https://www.la-fcca.org'
  end

  def close_browser
    @browser.quit
  end

  def save_pgf_files(arr_links_pgf)
    arr_links_pgf.each do |link|
      url = URI(@domain + link)
      @cobble.get_file(url, filename: "#{link[23..]}")
    end
  end

  def main
    @browser = @hammer.connect
    begin
      @browser.go_to('https://www.la-fcca.org/opiniongrid/opinionpub.php')

      @browser.evaluate <<~JS
        document.querySelector('#page_sizeUpper').value = '50'
      JS

      res = @browser.evaluate <<~JS
        document.querySelector('#page_sizeUpper').dispatchEvent(new Event('change'))
      JS

      logger.info "#{res}"

      sleep 5

      last_page = @browser.at_css('table.blue_dg_paging_table td a[title="last"]').attribute('onclick').match(/opinionp=(\d+)/)[1]

      while last_page.to_i > 1000
        sleep 2
        last_page = @browser.at_css('table.blue_dg_paging_table td a[title="last"]').attribute('onclick').match(/opinionp=(\d+)/)[1]
      end

      if @peon.give_list.empty?
        (1..last_page.to_i).each do |current|

          until @browser.at_css('table.blue_dg_paging_table td a[title="current"]')
            @browser.refresh
            sleep 4
          end

          # Save main pages
          html_file_name = "main_html_page_#{current}"
          if !File.exist?("#{storehouse}store/#{html_file_name}")
            @peon.put(content: @browser.body, file: html_file_name)
          else
            raise Exception.new 'This page was already parser'
          end

          @browser.at_css('table.blue_dg_paging_table td a[title="current"] + a').focus.click
          sleep 0.5
        end
      else
          until @browser.at_css('table.blue_dg_paging_table td a[title="current"]')
            @browser.refresh
            sleep 4
          end

          # Save main page
          html_file_name = "main_html_page_1_#{@parser.get_date(@browser.body)}"
          if !File.exist?("#{storehouse}store/#{html_file_name}")
            @peon.put(content: @browser.body, file: html_file_name)
          else
            raise Exception.new 'This page was already parser'
          end
      end
    rescue Exception => e
      logger.error "caught exception #{e}"
      sleep 0.5
      if e == "undefined method `attribute' for nil:NilClass" then retry end
    ensure
      close_browser
    end
  end

end

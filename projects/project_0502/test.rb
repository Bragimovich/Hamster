#docker stop $(docker ps -a -q)
#docker rm $(docker ps -a -q)

require 'rubygems'
require 'nokogiri'
require 'mechanize'
require 'active_support/core_ext/string/filters'
require 'active_support'
require 'ferrum'

#load './test.rb'
                
#doc = Nokogiri::HTML(html)
#doc = Nokogiri::HTML(html, &:noent)
#p arr2 = doc.traverse {|node| "HELLO #{node.text} HELLO" }
#p str = CGI.unescapeHTML(doc.to_s.squish.gsub(/[^[:print:]]/, ' '))
#str = "CGI::unescape_html('Head &lt;b&gt;south&lt;/b&gt; on &lt;b&gt;Hidden Pond Dr&lt;/b&gt; toward &lt;b&gt;Ironwood Ct&lt;/b&gt;')"
#html = Nokogiri::HTML(html)
#html.class
#prefixes = [
 # /\d+ \d+ \d+/,
 # /\d+-\d+-\d+/,	
 # /\d+\/\d+\/\d+/
#]
#re = Regexp.union(prefixes)

#def wrap_in_cdata(node)
#    node.inner_html = node.document.create_cdata(node.content)
#    node
#end
#fragment.xpath(".//span").each {|node| node.inner_html = node.document.create_cdata(node.content) }
#fragment.inner_html


SOURCE = 'https://ctrack.sccourts.org/public/caseSearch.do'

  def ferrum(url)
    host = "154.13.27.157"
    port = "5417"
    username = "noihtpkm"
    password = "h4kbu0kn5ruo"
    browser = Ferrum::Browser.new(
      browser_options: { 'no-sandbox': nil },
      browser_path: '/usr/bin/chromium-browser',
      timeout: 10000,
      proxy: {
        host: host,
        port: port,
        user: username,
        pasword: password
      }
    )
    #user_agent = FakeAgent.new.any
    #
    browser.headers.set(
      "User-Agent" => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'
    )

    ferrum_navigation(browser, url)
  ensure
    browser.reset
    browser.quit
  end

  def ferrum_navigation(browser, url)
    retries = 0
    begin
      sleep(5)
      browser.go_to(url)
      browser.network.wait_for_idle
      puts "#{retries}"
      sleep(10)
      puts "#{browser.body}"
      browser.refresh
      sleep(10)
      browser.back
      sleep(10)
      browser.forward
      sleep(10)
      parse_data(browser)
    rescue
      retries += 1
      retry if retries < 10
    end
  end

  def parse_data(browser)
    puts "#{browser.body}"
    browser.at_css('input[name=fromDt]').focus.type('01/01/2016')
    arr = Time.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s.split("-")             # 2022-09-12
    time_now = [arr[1], arr[2], arr[0]].join("/").to_s
    puts time_now
    browser.at_css('input[name=toDt]').focus.type(time_now, :enter)

    sleep(20)

    browser.css('table.FormTable tr.TableSubHeading').each do |td|
      data_names = []
      data_names << td.text
      p data_names
      #data_names.join("-----") write to file
    end

    begin
      if browser.css('table.pagingControls a')&.last && browser.css('table.pagingControls a')&.last.text == "Next"
        browser.css('table.pagingControls a')&.last.focus.click
        sleep(15)
        raise StandardError.new("Pages still exist!")
      end

      browser.css('table.FormTable tr.OddRow').each do |td|
        data = []
        puts td.css('a').first['href']
        data << td.text
        p data
        #data.join("-----") write to file
      end
      browser.css('table.FormTable tr.EvenRow').each do |td|
        data = []
        puts td.css('a').first['href']
        data << td.text
        p data
        #data.join("-----") write to file
      end



      sleep(10)
    rescue => error
      puts error
      retry if error.message == "Pages still exist!"
    end
  end


ferrum(SOURCE)

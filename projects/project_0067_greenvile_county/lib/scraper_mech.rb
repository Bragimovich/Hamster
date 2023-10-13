
class Scraper


  def initialize
    url_start = 'https://www2.greenvillecounty.org/scjd/publicindex/?AspxAutoDetectCookieSupport=0'
    # PaidProxy.where(is_http: 1).to_a.each do |pr|
    #   p pr
    # end
    @agent = get_agent
    #proxy=
    #@agent.set_proxy(proxy.ip, proxy.port, proxy.login, proxy.pwd)
    page  = @agent.get(url_start)
    url_search = 'https://www2.greenvillecounty.org/SCJD/PublicIndex/PISearch.aspx'
    #@cookies = @agent.cookies.map { |coockie| { coockie.name => coockie.value } }
    #p @cookies
    #temp_jar = @agent.cookie_jar

    #@agent.cookie_jar = temp_jar
    #page  = @agent.post('https://www2.greenvillecounty.org/scjd/publicindex/Disclaimer.aspx?AspxAutoDetectCookieSupport=0&AspxAutoDetectCookieSupport=1')
    #page  = @agent.get(url_search)

    mech_list = get_cases(page)
    #get_list_cases(mech_list)
  end

  def get_list_cases(mech_list)

    doc = Nokogiri::HTML(mech_list.body)
    cases_array = Array.new()
    doc.at_css("div#ContentPlaceHolder1_PanelSearchResults").css('tr')[1..].each do |line|
      list = line.css('td')
      cases_array.push({:name => list[0].content, :party_type => list[1].content, :case_id => list[2].content})
      #mech_list.links_with(href: %r{^javascript:[\w\W]+})
    end
    p cases_array
  end

  def get_agent

    pf = ProxyFilter.new
    begin

      proxy = PaidProxy.where(is_http: 1).where(ip: '45.72.97.42').to_a.shuffle.first

      raise "Bad proxy filtered" if pf.filter(proxy).nil?

      agent = Mechanize.new#{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}

      agent.user_agent_alias = "Windows Mozilla"
      agent.set_proxy(proxy.ip, proxy.port, proxy.login, proxy.pwd)

    rescue => e
      print Time.now.strftime("%H:%M:%S ").colorize(:yellow)
      puts e.message.colorize(:light_white)

      pf.ban(proxy)
      retry
    end

    agent
  end

  def get_cases(page)
    # ContentPlaceHolder1_ButtonAccept
    #q = page.fields_with(:value => 'Accept')
    #q = page.find_all_inputs()
    form = page.form_with()
    accept_button = form.button_with(:value => "Accept")
    form_search = form.click_button(accept_button)
    q = form_search.form_with(:id=>'form1')
    #(:name=> 'ctl00$ContentPlaceHolder1$TextBoxDateFrom')
    #p q['ctl00$ContentPlaceHolder1$TextBoxDateFrom']
    q['ctl00$ContentPlaceHolder1$TextBoxDateFrom']='01/01/2021'
    q['ctl00$ContentPlaceHolder1$TextBoxDateTo']='01/03/2021'
    q['ctl00$ContentPlaceHolder1$DropDownListDateFilter']='Filed'
    search_button = q.button_with(:value => "Search")
    list_url = q.click_button(search_button)
    list_url.links_with(href: %r{^javascript:[\w\W]+}).map do |ll|
      f = ll.click
      p f
    end
  end

end


# frozen_string_literal: true

class Scraper < Connect
  attr_writer :link
  def link_by(char_name, num)
    @link = "https://www.osbar.org/members/membersearch.asp?bar=&first=#{char_name}&last=&scity=&pastnames=&cp=#{num}"
  end

  def page_checked?
    @result = connect(url: @link)
    @result.code == '200'
  end

  def html
   @result.body
  end

  def web_page
    web = "https://www.osbar.org/members/#{@link}"
    res = connect(url: web)
    res.body
  end
  
  def check_bar_n?(bar)
    url = "https://www.osbar.org/members/membersearch_display.asp?b=#{bar}&s=1"
    @page = connect(url: url)
    @page.code == '200'
  end
  
  def bar_n_html
    @page.body
  end
  
  def lawyer_bar
    @link.split('=').last
  end
end

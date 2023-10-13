require 'csv'
require_relative './parser_class'

class ScraperClass < Hamster::Scraper
  BASE_URL = "https://www.ams.usda.gov/press-releases?field_term_programs_offices_target_id=All&date=&keys=&page="
  BASE_URL2 = "https://www.ams.usda.gov"
  SUB_FOLDER = 'US_Department_of_Agriculture'
 
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}

    # Map of file_name and link where key is the filename and value is the link
    @downloaded_file_names = {}
    @dir_path = @_storehouse_ + 'filename_link.csv'
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @downloaded_file_names[x[0]] = x[1] }
    end
  end

  def download
    # Note: Need this class here to parser inner divs and then save them in file.
    @parser_obj = ParserClass.new()
    save_html_pages
  end

  private

  def save_html_pages
    initial_page = 0
    while true
      link = BASE_URL + initial_page.to_s

      outer_page, status = download_web_page(link) 
      initial_page += 1
      next if status != 200
      
      # breaking condition
      break if @parser_obj.get_inner_divs(outer_page.body).count == 0

      file_md5 = Digest::MD5.hexdigest(link)
      file_name = "outer_page_" + file_md5 + '.gz'
      save_file(outer_page ,file_name)
      save_csv(file_name , link)
      
      @parser_obj.get_inner_divs(outer_page.body).each do |inner_div|
        link = @parser_obj.get_article_link_from_inner_div(inner_div)
        constructed_article_link = BASE_URL2 + link
        file_md5 = Digest::MD5.hexdigest(constructed_article_link)
        file_name = file_md5 + '.gz'
        next if @downloaded_file_names[file_name].present?
        inner_page, status = download_web_page(constructed_article_link)
        next if status != 200
        save_file(inner_page, file_name)
        save_csv(file_name, constructed_article_link)
      end
    end
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name,link)
    rows = [[file_name , link]]
    File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
  end
   
  def connect_to_prime(url)
    # function to parse redirected url
    retries = 0
    begin
      puts "Processing Redirected URL -> #{url}".red
      begin
        response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      rescue NoMethodError
        return [nil ,400]
      end
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    return [response , response&.status]
  end

  def download_web_page(url, inner = false)
    retries = 0
    begin
      puts "Processing URL #{inner} -> #{url}".yellow
      begin
        response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter)
      rescue NoMethodError
        return [nil ,400]
      end
      
      if [301, 302].include? response&.status
        url = response.headers["location"]
        puts "URL is redirected to -> #{url}".yellow
        response = connect_to_prime(url)
        return [response[0] , response[1]]
      end
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    return [response , response&.status]
  end

  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end

end 

# frozen_string_literal: true


def make_md5(news_hash)
  all_values_str = ''
  columns = %i[title release_no link date]
  columns.each do |key|
    if news_hash[key].nil?
      all_values_str = all_values_str + news_hash[key.to_s].to_s
    else
      all_values_str = all_values_str + news_hash[key].to_s
    end
  end
  Digest::MD5.hexdigest all_values_str
end


def run_for_all_years(start_year=2018, job='g', counts=10)
  job='g' if job.nil?
  year=start_year
  while year!=1995
    delete_null_rows(year) if job=='g'
    Scraper.new(year, job, counts)
    year=year-1
    break if job == 'ts'
  end
end


class Scraper < Hamster::Scraper

  def initialize(year=2021, job='g', counts=0)
    super
    @counts = counts
    @store_folder  = "#{storehouse}#{year}/" #
    #p @store_folder
    #FileUtils.mkdir_p(@store_folder)
    @peon = Peon.new(@store_folder)
    gathering(year) if job=='g'
    storing(year) if job=='s'
    test_storing(year) if job=='ts'
    update_problem_date(year) if job=='date'

  end


  def gathering(year)
    url = "https://www.nrc.gov/reading-rm/doc-collections/news/#{year}/index.html"
    p url
    i=1
    news_html_page = connect_to(url).body
    list_news = parse_list_news(news_html_page, year)
    release_no_on_page = list_news.map { |q| q[:release_no] }
    existing_release_no = get_title(release_no_on_page).keys
    p existing_release_no
    agent = Dasher.new(:using=>:cobble)
    list_news.each do |news_short|
      next if news_short[:release_no].in? existing_release_no
      news_short[:link]="https://www.nrc.gov"+news_short[:link]
      #p news_short
      news_short[:md5_hash] = make_md5(news_short)
      if news_short[:link].match(/.pdf$/)
        begin
          #pdf_file = agent.get_file(news_short[:link], filename: "#{@store_folder}store/#{news_short[:release_no]}" )
          pdf_file = agent.get(news_short[:link])
          @peon.put content: pdf_file, file: "#{news_short[:release_no]}"
        rescue => error
          p error
          File.open("logs/proj_98", "a") do |file|
            file.write("#{Date.today.to_s}| #{news_short[:release_no]} : #{error.to_s} \n")
          end
          next
        end
        # begin
        #   @peon.put content: pdf_file, file: "#{news_short[:release_no]}"
        # rescue => e
        #   p e
        # end
      else
        begin
          html_file = agent.get(news_short[:link])
        rescue => error
          File.open("logs/proj_98_html", "a") do |file|
            file.write("#{Date.today.to_s}| #{news_short[:release_no]} : #{error.to_s} \n")
          end
          next
        end

        @peon.put content: html_file, file: "#{news_short[:release_no]}", subfolder: 'html'
      end
      put_general_data(news_short)
      #break if i==@counts
      i+=1
    end
  end

  def update_problem_date(year)
    url = "https://www.nrc.gov/reading-rm/doc-collections/news/#{year}/index.html"
    p url
    i=1
    news_html_page = connect_to(url).body
    parse_list_news(news_html_page, year).each do |news_short|
      update_date(news_short)
    end
  end

  def test_storing(year)
    array_files = Dir.glob('*', base: @store_folder+'trash')
    # archives = Dir.glob('*.gz', base: @store_folder+'trash')
    # array_files = array_files - archives
    #array_files = ["III-21-017", "21-028", "II-21-020", "III-21-007", "III-21-013", "III-21-012", "III-21-016", "21-029", "III-21-006", "21-022", "I-21-004", "21-026", "III-21-009", "21-027", "III-21-008", "IV-21-010", "21-023", "I-21-005", "21-024", "II-21-018", "IV-21-007", "21-020", "I-21-006", "21-030", "IV-21-006", "21-021", "I-21-007", "21-025", "II-21-019", "III-21-011", "IV-21-009", "III-21-015", "II-21-016", "III-21-014", "II-21-017", "III-21-010", "IV-21-008"]
    #array_files = ['21-022']
    realese_no_title = get_title(array_files)
    realese_no_title.each do |realease_no, title|
          p realease_no
          pdf_file = @store_folder+'trash/' + realease_no
          if year==2015
            news = read_pdf_file_2015(pdf_file, realease_no, title)
          elsif year>2013
            news = read_pdf_file_2013_2021(pdf_file, realease_no, title)
          elsif year==2013
            news = read_pdf_file_2013(pdf_file, realease_no, title)
          elsif year>1999
            news = read_pdf_file_2000_2012(pdf_file, year)
          elsif year==1999
            news = read_pdf_file_1999(pdf_file, realease_no, title)
          elsif year==1998
            news = read_pdf_file_1998(pdf_file, realease_no, title)
          end
          next if news.nil?
          news[:release_no] = realease_no
          put_full_data(news)
    end
  end

  def storing(year)
    array_files = @peon.give_list.map! { |filename| filename.split('/')[-1].split('.gz')[0] }
    #array_files = Dir[@store_folder+'store/*']
    #array_files_to_title = array_files.map! { |filename| filename.split('/')[-1].split('.')[0] }

    realese_no_title = get_title(array_files)
    array_files.each do |filename|
      realease_no = filename.split('/')[-1].split('.')[0]
      title = realese_no_title[realease_no]
      #pdf_file = storehouse+'store/' + filename

      # filename = realease_no + '.gz'
      @peon.copy_and_unzip_temp(file: filename)
      pdf_file = @store_folder+'trash/' + realease_no
      if year==2015
        news = read_pdf_file_2015(pdf_file, realease_no, title)
      elsif year>2013
        news = read_pdf_file_2013_2021(pdf_file, realease_no, title)
      elsif year==2013
        begin
          news = read_pdf_file_2013(pdf_file, realease_no, title)
        rescue
          news = read_pdf_file_2000_2012(pdf_file, year)
        end
      elsif year==2001
        news = read_html_file_2001(pdf_file)
      elsif year>1999
        news = read_pdf_file_2000_2012(pdf_file, year)
      elsif year==1999
        news = read_pdf_file_1999(pdf_file, realease_no, title)
      elsif year==1998
        news = read_pdf_file_1998(pdf_file, realease_no, title)
      elsif year<1998
        news = read_pdf_file_1996(pdf_file, year)
      end

      next if news.nil?
      news[:release_no] = realease_no
      put_full_data(news)
      @peon.move(file: filename)
    end
    #p news
    #
    @peon.throw_temps
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

end
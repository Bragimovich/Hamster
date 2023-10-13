# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize(update=0, test=0)
    super
    q=0
    begin
      if update<0
        update = -2020 if update.class==TrueClass
        update = update*-1
        # add_info_to_old_rows(update) if test==0
        add_info_to_old_rows_dasher(update) #if test==1
      else
        scrape(update)
      end

    rescue ActiveRecord::ConnectionNotEstablished => error
      p error
      CongressionalRecordJournals.connection.reconnect!
      q+=1
      retry if q<6
      CongressionalRecordJournals.connection.close
    rescue => error
      p error
      CongressionalRecordJournals.connection.close
    end

  end

  # update: 0 – if it save all data, >0 – if it just take only last data for last year
  def scrape(update)
    pageSize = 100
    page_start=0
    #sorting_start = "issueAsc"
    sorting_start = "issueDesc" #if update==1
    start_year = -167 - (2021-year)
    continue_filename = "#{storehouse}/place_to_continue"

    if File.exist? continue_filename and update==0
      continue_line=''
      File.open(continue_filename, 'r') { |file| continue_line=file.read.split(":")}
      page_start = continue_line[1].to_i
      start_year = continue_line[0].to_i
      sorting_start = continue_line[2]
    end


    (start_year..-141).each do |volume|
      volume=volume*-1
      last_page=-1

      if page_start==0
        page=1
      else
        page=page_start
        page_start=0
      end

      sorting = sorting_start
      path_to_save = "#{storehouse}#{volume}/"
      @peon = Peon.new(path_to_save)
      dasher = Dasher.new(:using=>:hammer, pc:0, headless:false)
      #conn = Hamster::Scraper::Dasher.new('https://www.congress.gov/congressional-record/', using: :cobble, use_proxy:25)
      loop do
        url = "https://www.congress.gov/search?pageSort=#{sorting}&q=%7B%22source%22%3A%22congrecord%22%2C%22cr-year-and-volume%22%3A%22#{volume}%22%7D&pageSize=#{pageSize}&page=#{page}"
        p url
        #main_page = connect_to(url) # Get page with list of articles #conn.smash(url: url) #
        main_page= dasher.get(url)
        #browser = dasher.connection
        #browser.screenshot(path: "5555433330.png")
        #sleep(15)
        #main_page = browser.body
        #browser.screenshot(path: "5555433331.png")
        #p main_page
        redo unless main_page
        links_from_page, all_page = parse_main_page(main_page)
        last_page = all_page-page+1 if last_page==-1
        existing_links_md5_hash = get_existing_links_md5_hash(links_from_page)
        existing_links = get_existing_links(links_from_page) if update ==1

        #return 0 if existing_links.length==links_from_page.length and update!=0
        q=0
        p links_from_page
        links_from_page.each do |link|
          next if link.in? existing_links if update == 1
          p link
          article_page = dasher.get(link)# connect_to(link) #conn.smash(url: link)
          unless article_page
            p "q: #{q}"
            if q>0
              q = 0
              next
            end
            q+=1
            redo
          end
          record = parse_article_page(article_page)
          next if record.nil?
          save_file(link, article_page)

          record[:link] = link
          record[:md5_hash] = make_md5(record)
          next if existing_links_md5_hash.include?(record[:md5_hash])
          begin
            put_data_to_db(record)
            #save_file(link, article_page.body)
          rescue => error
            p error
            File.open("#{storehouse}logs", 'a') { |file| file.write("#{record[:link]}:#{record[:date]}:#{error}") }
            next
          end

        end
        break if last_page==0
        break if existing_links.length==pageSize and update==1

        if page == 250
          sorting = "issueAsc"
          page = 0
        end

        File.open(continue_filename, 'w') { |file| file.write("-#{volume}:#{page}:#{sorting}:") }
        page = page + 1
        last_page = last_page - 1
        CongressionalRecordJournals.connection.reconnect!
        dasher.close
      end
    end
  end


  def add_info_to_old_rows(update=2021)
    limit = 1000
    q=0
    year=update
    loop do
      volume = 168 - (2021-year)
      path_to_save = "#{storehouse}#{volume}/"
      @peon = Peon.new(path_to_save)

      loop do
        records = get_row_for_update(limit, year)
        records.each do |record|
          link = record[:link]
          article_page = connect_to link # Get article page
          if article_page.status>399
            next if q>1
            q+=1
            redo
          end
          record = parse_article_page(article_page.body)
          add_additional_info_to_record(record, link)
          save_file(link, article_page.body)
        end

        break if records.to_a.length<limit
      end

      break if year == 2005
      year = year-1
    end
  end


  def add_info_to_old_rows_dasher(update=2021)
    limit = 1000

    year=update

    conn = Hamster::Scraper::Dasher.new('https://www.congress.gov/congressional-record/', using: :cobble, use_proxy:25)

    loop do
      volume = 168 - (2021-year)
      path_to_save = "#{storehouse}#{volume}/"
      @peon = Peon.new(path_to_save)
      q = 0 # Counter for trying
      loop do
        records = get_row_for_update(limit, year)
        records.each do |record|
          link = record[:link]
          article_page = conn.smash(url: link)
          unless article_page
            p "q: #{q}"
            if q>1
              q = 0
              next
            end
            q+=1
            redo
          end
          record = parse_article_page(article_page.body)
          add_additional_info_to_record(record, link)
          save_file(link, article_page.body)
        end
        break if records.to_a.length<limit
      end

      break if year == 2005
      year = year-1
    end
  end



  def save_file(link, body)
    filename = link.split('/')[-1]
    @peon.put content: body, file: filename
  end


  COLUMNS = %i[title journal date section link]

  def make_md5(data_hash)
    all_values_str = ''
    COLUMNS.each do |key|
      if data_hash[key].nil?
        all_values_str = all_values_str + data_hash[key.to_s].to_s
      else
        all_values_str = all_values_str + data_hash[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end

end





def delete_similar_links(year=2021)
  all_link = []
  limit = 500
  page = 0
  loop do
    offset=page*limit
    records = CongressionalRecordJournals.where("YEAR(date)=#{year}").order(:link).limit(limit).offset(offset)
    records.each do |record|
      if record.link.in?(all_link)
        p record.link
        record.delete
      end
      all_link.push(record.link)
    end
    break if records.to_a.length<limit
    page+=1
  end

end
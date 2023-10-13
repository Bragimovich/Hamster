# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize(update=0, work='d')
    super
    q=0
    begin
      update =
        if update.nil?
          0
        else
          1
        end

      scrape(update) if work == 'd' or update == 1
      store_all if work == 's'
      store_text if work == 't'
      get_summary_update if work == 'sum'
      put_pdf_on_aws
    rescue ActiveRecord::ConnectionNotEstablished => error
      p error
      CongressionalLegislationInfo.connection.reconnect!
      q+=1
      retry if q<6
      CongressionalLegislationInfo.connection.close
    rescue
      CongressionalLegislationInfo.connection.close
    end

  end

  # update: 0 – if it save all data, >0 – if it just take only last data for last year
  def scrape(update)
    pageSize = 100
    page_start=0

    sorting_start = "latestAction%3Adesc"
    sorting_start = "latestAction%3Adesc" if update==1
    start_congress = -117
    continue_filename = "#{storehouse}/place_to_continue"

    if File.exist? continue_filename and update==0
      continue_line=''
      File.open(continue_filename, 'r') { |file| continue_line=file.read.split(":")}
      page_start = continue_line[0].to_i
      sorting_start = continue_line[1]
    end

    cobble = Dasher.new(:using=>:cobble)

    (start_congress..-116).each do |congress|
      congress=congress*-1
      last_page=-1

      if page_start==0
        page=1
      else
        page=page_start
        page_start=0
      end

      sorting = sorting_start
      path_to_save = "#{storehouse}#{congress}/"
      @peon = Peon.new(path_to_save)
      #conn = Hamster::Scraper::Dasher.new('https://www.congress.gov/congressional-record/', using: :cobble, use_proxy:25)
      loop do
        url = "https://www.congress.gov/search?q=%7B%22source%22%3A%22legislation%22%2C%22congress%22%3A%22#{congress}%22%7D&pageSort=#{sorting}&pageSize=100&page=#{page}"
        p url
        main_page = cobble.get(url) # Get page with list of articles #conn.smash(url: url) #
        redo unless main_page
        records, all_page = ParserPage.parse_main_page(main_page)
        last_page = all_page-page+1 if last_page==-1

        #leg_ids = records.map {|rec| rec[:leg_id]}

        #existing_leg_ids = Keeper.get_existing_legs(leg_ids, congress)
        #return 0 if existing_leg_ids.length==records.length and update!=0


        records.each do |origin_record|
          #next if origin_record[:leg_id].in? existing_leg_ids
          origin_record[:congress] = congress
          parser = ParserOnePage.new(**origin_record)
          keeper = Keeper.new(origin_record[:leg_id])
          link_additional = 'all-info'
          article_page = cobble.get(origin_record[:link] + '/' + link_additional)
          save_file(article_page, origin_record[:leg_id]+ '_'+link_additional)

          record = parser.parse_article_page(article_page)
          commities = record[:committees].map {|com| com[:committees]}
          p commities
          keeper.check_existing_committees(commities)
          #exit 0 if !commities.empty?

          link_additional = 'text'
          text_page = cobble.get(origin_record[:link] + '/' + link_additional)
          save_file(text_page, origin_record[:leg_id] + '_' + link_additional)
          texts = [parser.get_text(text_page)]
          if texts[0][:another_texts]
            texts[0][:another_texts].each do |another_text|
              text_page = cobble.get(origin_record[:link] + '/' + link_additional + "/" + another_text)
              save_file(text_page, origin_record[:leg_id] + '_' + link_additional + "_" + another_text)
              text = parser.get_text(text_page)
              text.delete(:another_texts)
              texts.push(text)
            end
            texts[0].delete(:another_texts)
          end

          record[:texts] = texts
          keeper.insert_all(record)

          next if record.nil?

          # begin
          #   put_data_to_db(record)
          # rescue => error
          #   File.open("#{storehouse}logs", 'a') { |file| file.write("#{record[:link]}:#{record[:date]}:#{error}") }
          #   next
          # end

        end

        break if last_page==0

        if page == 250
          sorting = "latestAction%3Aasc"
          page = 0
        end

        File.open(continue_filename, 'w') { |file| file.write("#{page}:#{sorting}:") }
        page = page + 1
        last_page = last_page - 1
        CongressionalLegislationInfo.connection.reconnect!

        break if update == 1 #leg_ids.length<100 and

      end
    end
  end

  def store_all
    start_congress = -117

    (start_congress..-116).each do |congress|
      congress = congress * -1
      path_to_save = "#{storehouse}#{congress}/"
      @peon = Peon.new(path_to_save)


      @peon.give_list.each do |leg|
        next if leg.match("_text")
        leg_id = leg.split('_all')[0]

        parser = ParserOnePage.new({leg_id:leg_id, congress: congress})
        keeper = Keeper.new(leg_id)

        article_page = @peon.give(file:leg)

        record = parser.parse_article_page(article_page)

        keeper.insert_all(record)
        # keeper.insert_data_to_table(record[:committees], :committees)
        # keeper.insert_data_to_table(record[:cosponsors], :cosponsors)


      end

    end

  end

  def store_text
    cobble = Dasher.new(:using=>:cobble)
    link_additional = 'text'
    limit = 100
    page = 0
    loop do
      offset = page * limit
      rows = CongressionalLegislationInfo.where.not(data_source_url:nil).limit(limit).offset(offset)

      leg_ids = rows.map { |row| row.leg_id  }

      existing_leg_ids = existing_text(leg_ids)

      rows.each do |text_row|
        next if text_row.leg_id.in?(existing_leg_ids)
        text_page = cobble.get(text_row.data_source_url + '/' + link_additional)
        parser = ParserOnePage.new({leg_id: text_row.leg_id})
        keeper = Keeper.new(text_row.leg_id)

        texts = [parser.get_text(text_page)]
        texts[0][:data_source_url] = text_row.data_source_url
        if texts[0][:another_texts]
          texts[0][:another_texts].each do |another_text|
            text_page = cobble.get(text_row.data_source_url + '_' + link_additional + "_" + another_text)
            text = parser.get_text(text_page)
            text.delete(:another_texts)
            text[:data_source_url] = text_row.data_source_url
            texts.push(text)
          end
          texts[0].delete(:another_texts)
        end
        keeper.insert_data_to_table(texts, :texts)
      end
      break if existing_leg_ids.to_a.length>0 and update == 1
      page = page +1
    end

  end

  def put_pdf_on_aws
    @s3 = AwsS3.new(bucket_key = :loki, account=:loki)
    limit = 100
    page = 0
    md5_class = MD5Hash.new(:columns=>%i[leg_id pdf_link ])
    loop do
      offset = page * limit
      rows = CongressionalLegislationTexts.where.not(pdf_link:nil).where(aws_link:nil).limit(limit)
      rows.each do |text_row|
        key_start = "congressional_legislation_#{text_row.leg_id}"
        p key_start
        url_pdf_on_aws = save_to_aws(text_row.pdf_link, key_start)
        text_row.aws_link = url_pdf_on_aws
        text_row.md5_hash = md5_class.generate({leg_id: text_row.leg_id, pdf_link: text_row.pdf_link })
        text_row.save
      end
      break if rows.to_a.length<limit
      page = page + 1
    end
  end

  def get_summary_update
    cobble = Dasher.new(:using=>:cobble)
    CongressionalLegislationInfo.where(summary:nil).where.not(data_source_url:nil).each do |leg|
      parser = ParserOnePage.new({leg_id:leg.leg_id, congress:leg.congress, link: leg.data_source_url})
      keeper = Keeper.new(leg.leg_id)
      article_page = cobble.get(leg.data_source_url)
      record = parser.parse_article_page(article_page)
      keeper.insert_all(record)
    end

  end






  private
  def save_file(body, filename)
    @peon.put content: body, file: filename
  end

  def save_to_aws(url_file, key_start)
    cobble = Dasher.new(:using=>:cobble)
    body = cobble.get(url_file)
    key = key_start + Time.now.to_i.to_s + '.pdf'
    @s3.put_file(body, key, metadata={url: url_file})
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
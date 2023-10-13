require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def initialize
    super
    @courts = [
      { 'name': "Supreme+Court", 'path': "supreme", 'id': 314 },  # Supreme
      { 'name': "First+District+Appellate+Court", 'path': "1st", 'id': 423 },      # 1st District Appellate
      { 'name': "Second+District+Appellate+Court", 'path': "2nd", 'id': 424 },      # 2nd District Appellate
      { 'name': "Third+District+Appellate+Court", 'path': "3rd", 'id': 425 },      # 3rd District Appellate
      { 'name': "Fourth+District+Appellate+Court", 'path': "4th", 'id': 426 },      # 4th District Appellate
      { 'name': "Fifth+District+Appellate+Court", 'path': "5th", 'id': 427 }       # 5th District Appellate
    ]
    @keeper = Keeper.new
    @scraper = Scraper.new
    @parser = Parser.new
    @saved = 1
  end

  def download(parts = false, courts = @courts)
    @keeper.add_run('Download start!') unless parts
    url = 'https://www.illinoiscourts.gov/top-level-opinions/'
    date_now = Date.today
    date_day = date_now.day.to_s
    date_month = date_now.month.to_s
    date_year = date_now.year.to_s
    date_to = "#{date_month}%2F#{date_day}%2F#{date_year}"
    date_from = '01%2F01%2F2016'
    courts.each do |court|
      court_name = court[:name]
      court_path = court[:path]
      cookie, view_state, view_state_gen = @scraper.get_cookie(url)
      (1..).each do |page|
        req = '__EVENTTARGET=ctl00%24ctl04%24gvDecisions&'
        req += "__EVENTARGUMENT=Page%24#{page}&"  # page
        req += '__LASTFOCUS=&'
        req += "__VIEWSTATE=#{view_state}&"
        req += "__VIEWSTATEGENERATOR=#{view_state_gen}&"
        req += 'ctl00%24header%24search%24txtSearch=&'
        req += 'ctl00%24ctl04%24txtFilterName=&'
        req += 'ctl00%24ctl04%24txtFilterPostingFrom=4%2F28%2F2012&'
        req += 'ctl00%24ctl04%24txtFilterPostingTo=4%2F28%2F2023&'
        req += 'ctl00%24ctl04%24ddlFilterFilingDate=Custom+Date+Range&'
        req += "ctl00%24ctl04%24txtFilterFilingFrom=#{date_from}&" # date from
        req += "ctl00%24ctl04%24txtFilterFilingTo=#{date_to}&" # date to
        req += "ctl00%24ctl04%24ddlFilterCourtType=#{court_name}&" # court
        req += 'ctl00%24ctl04%24ddlFilterStatus=&'
        req += 'ctl00%24ctl04%24hdnSortField=FilingDate&'
        req += 'ctl00%24ctl04%24hdnSortDirection=DESC'
        table_info = @scraper.table_info(url, cookie, req, page)
        break if table_info.blank?
        table_info.each do |item|
          link = item[:link]
          case_id = item[:case_id]
          item[:file_name], item[:link_original], item[:link] = scraper.pdf(link, court_path, case_id) unless link.blank?
          file_save(item, court_path)
        rescue StandardError => e
          message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
          logger.error message
        end
      rescue StandardError => e
        message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
        logger.error message
      end
    rescue StandardError => e
      message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
      logger.error message
      message_send(message)
    end
    logger.info 'Download finish!' unless parts
    @keeper.update_run('Download finish!') unless parts
    message_send('Download finish!') unless parts
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def file_save(item, court_path)
    file = Digest::MD5.hexdigest(item[:case_id]).to_s
    file = "#{file}.html"
    content = "<p><b>file_name: </b><span class='file_name'>#{item[:file_name]}</span></p>"
    content += "<p><b>link_original: </b><a class='link_original' href='#{item[:link_original]}'>#{item[:link_original]}</a></p>"
    content += "<p><b>link: </b><a class='link' href='#{item[:link]}'>#{item[:link]}</a></p>"
    content += "<p><b>case_name: </b><span class='case_name'>#{item[:case_name]}</span></p>"
    content += "<p><b>citation: </b><span class='citation'>#{item[:citation]}</span></p>"
    content += "<p><b>case_id: </b><span class='case_id'>#{item[:case_id]}</span></p>"
    content += "<p><b>filing_date: </b><span class='filing_date'>#{item[:filing_date]}</span></p>"
    content += "<p><b>court: </b><span class='court'>#{item[:court]}</span></p>"
    content += "<p><b>decision_type: </b><span class='decision_type'>#{item[:decision_type]}</span></p>"
    content += "<p><b>status: </b><span class='status'>#{item[:status]}</span></p>"
    content += "<p><b>notes: </b><span class='notes'>#{item[:notes]}</span></p>"
    peon.put(file: file, content: content, subfolder: court_path)
    logger.info "[#{@saved}] File save! #{item[:case_id]} #{court_path}/#{file}".green
    @saved += 1
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def store(parts = false, courts = @courts, run = nil)
    @keeper.update_run('Store start!')
    run_id = run.blank? ? @keeper.get_run : run
    index = 1
    courts.each do |court|
      court_path = court[:path]
      court_id = court[:id]
      pdf_path = "#{court_path}_PDF"
      files = peon.give_list(subfolder: court_path)
      files = files.sort
      files.each do |file|
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: court_path)
        info, add_info, parties, link = @parser.info_parse(page, pdf_path, court_id)
        @keeper.add_info(info, run_id, index, link) unless info.blank?
        @keeper.add_add_info(add_info, run_id) unless add_info.blank?
        index += 1
        parties.each do |party|
          @keeper.add_party(party, run_id) unless party.blank?
        end
        peon.move(file: file, from: court_path)
      rescue StandardError => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
      end
    rescue StandardError => e
      message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
      logger.error message
      message_send(message)
    end
    peon.throw_trash
    peon.throw_temps
    @keeper.update_run('Store finish!') unless parts
    logger.info 'Store finish!' unless parts
    message_send('Store finish!') unless parts
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def parts
    @keeper.add_run('Download start!')
    run_id = @keeper.get_run
    @courts.each do |court|
      download(true,[court])
      store(true,[court], run_id)
    end
    @keeper.update_run('Store finish!')
    logger.info 'Store finish!'
    message_send('Store finish!')
  end
end

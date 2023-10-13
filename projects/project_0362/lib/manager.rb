require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def initialize
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
    @parser = Parser.new
  end

  def download
    case_id_oe
    case_id_sjc
    case_id_far
    case_id_dar
    case_id_bd
    case_id_sj
    case_id_sj_m
    case_id_p
    case_id_j
    message_send('Download finish!')
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def case_id_oe
    drop_index = 0
    index = 130
    closed = @keeper.get_closed('%OE%')
    loop do
      case_id = "OE-#{format('%04d', index)}"
      url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
      if closed.include? case_id
        logger.info "Case '#{case_id}' closed. SKIP"
      else
        page = @scraper.page(url)
        drop_index += 1 if page&.status != 200
        break if drop_index > 50
        if page&.status == 200
          attorney_links = @parser.attorney_links(page)
          attorneys = []
          attorney_links.each do |attorney_link|
            attorney_page = @scraper.page(attorney_link[:link])
            next if attorney_page&.status != 200
            attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
          end
          page_save(page, attorneys, url, case_id, 'OE')
          drop_index = 0
        end
      end
      index += 1
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_sjc
    drop_index = 0
    index = 12030
    closed = @keeper.get_closed('%SJC%')
    loop do
      case_id = "SJC-#{format('%05d', index)}"
      url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
      if closed.include? case_id
        logger.info "Case '#{case_id}' closed. SKIP"
      else
        page = @scraper.page(url)
        drop_index += 1 if page&.status != 200
        break if drop_index > 50
        if page&.status == 200
          attorney_links = @parser.attorney_links(page)
          attorneys = []
          attorney_links.each do |attorney_link|
            attorney_page = @scraper.page(attorney_link[:link])
            next if attorney_page&.status != 200
            attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
          end
          page_save(page, attorneys, url, case_id, 'SJC')
          drop_index = 0
        end
      end
      index += 1
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_far
    drop_index = 0
    index = 24013
    closed = @keeper.get_closed('%SJC%')
    loop do
      case_id = "FAR-#{format('%05d', index)}"
      url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
      if closed.include? case_id
        logger.info "Case '#{case_id}' closed. SKIP"
      else
        page = @scraper.page(url)
        drop_index += 1 if page&.status != 200
        break if drop_index > 200
        if page&.status == 200
          attorney_links = @parser.attorney_links(page)
          attorneys = []
          attorney_links.each do |attorney_link|
            attorney_page = @scraper.page(attorney_link[:link])
            next if attorney_page&.status != 200
            attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
          end
          page_save(page, attorneys, url, case_id, 'FAR')
          drop_index = 0
        end
      end
      index += 1
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_dar
    drop_index = 0
    index = 24012
    closed = @keeper.get_closed('%DAR%')
    loop do
      case_id = "DAR-#{format('%05d', index)}"
      url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
      if closed.include? case_id
        logger.info "Case '#{case_id}' closed. SKIP"
      else
        page = @scraper.page(url)
        drop_index += 1 if page&.status != 200
        break if drop_index > 200
        if page&.status == 200
          attorney_links = @parser.attorney_links(page)
          attorneys = []
          attorney_links.each do |attorney_link|
            attorney_page = @scraper.page(attorney_link[:link])
            next if attorney_page&.status != 200
            attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
          end
          page_save(page, attorneys, url, case_id, 'DAR')
          drop_index = 0
        end
      end
      index += 1
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_bd
    current_year = DateTime.now.year
    closed = @keeper.get_closed('%BD%')
    (2016..current_year).each do |year|
      drop_index = 0
      index = 1
      loop do
        case_id = "BD-#{year}-#{format('%03d', index)}"
        url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
        if closed.include? case_id
          logger.info "Case '#{case_id}' closed. SKIP"
        else
          page = @scraper.page(url)
          drop_index += 1 if page&.status != 200
          break if drop_index > 50
          if page&.status == 200
            attorney_links = @parser.attorney_links(page)
            attorneys = []
            attorney_links.each do |attorney_link|
              attorney_page = @scraper.page(attorney_link[:link])
              next if attorney_page&.status != 200
              attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
            end
            page_save(page, attorneys, url, case_id, 'BD')
            drop_index = 0
          end
        end
        index += 1
      end
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_sj
    current_year = DateTime.now.year
    closed = @keeper.get_closed('%SJ-%')
    (2016..current_year).each do |year|
      drop_index = 0
      index = 1
      loop do
        case_id = "SJ-#{year}-#{format('%04d', index)}"
        url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
        if closed.include? case_id
          logger.info "Case '#{case_id}' closed. SKIP"
        else
          page = @scraper.page(url)
          drop_index += 1 if page&.status != 200
          break if drop_index > 50
          if page&.status == 200
            attorney_links = @parser.attorney_links(page)
            attorneys = []
            attorney_links.each do |attorney_link|
              attorney_page = @scraper.page(attorney_link[:link])
              next if attorney_page&.status != 200
              attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
            end
            page_save(page, attorneys, url, case_id, 'SJ')
            drop_index = 0
          end
        end
        index += 1
      end
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_sj_m
    current_year = DateTime.now.year
    closed = @keeper.get_closed('%SJ-%')
    (2016..current_year).each do |year|
      drop_index = 0
      index = 1
      loop do
        case_id = "SJ-#{year}-M#{format('%03d', index)}"
        url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
        if closed.include? case_id
          logger.info "Case '#{case_id}' closed. SKIP"
        else
          page = @scraper.page(url)
          drop_index += 1 if page&.status != 200
          break if drop_index > 50
          if page&.status == 200
            attorney_links = @parser.attorney_links(page)
            attorneys = []
            attorney_links.each do |attorney_link|
              attorney_page = @scraper.page(attorney_link[:link])
              next if attorney_page&.status != 200
              attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
            end
            page_save(page, attorneys, url, case_id, 'SJ_M')
            drop_index = 0
          end
        end
        index += 1
      end
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_p
    current_year = DateTime.now.year
    closed = @keeper.get_closed('%-P-%')
    (2016..current_year).each do |year|
      drop_index = 0
      index = 1
      loop do
        case_id = "#{year}-P-#{format('%04d', index)}"
        url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
        if closed.include? case_id
          logger.info "Case '#{case_id}' closed. SKIP"
        else
          page = @scraper.page(url)
          drop_index += 1 if page&.status != 200
          break if drop_index > 50
          if page&.status == 200
            attorney_links = @parser.attorney_links(page)
            attorneys = []
            attorney_links.each do |attorney_link|
              attorney_page = @scraper.page(attorney_link[:link])
              next if attorney_page&.status != 200
              attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
            end
            page_save(page, attorneys, url, case_id, 'P')
            drop_index = 0
          end
        end
        index += 1
      end
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def case_id_j
    current_year = DateTime.now.year
    closed = @keeper.get_closed('%-J-%')
    (2016..current_year).each do |year|
      drop_index = 0
      index = 1
      loop do
        case_id = "#{year}-J-#{format('%04d', index)}"
        url = "https://www.ma-appellatecourts.org/docket/#{case_id}"
        if closed.include? case_id
          logger.info "Case '#{case_id}' closed. SKIP"
        else
          page = @scraper.page(url)
          drop_index += 1 if page&.status != 200
          break if drop_index > 50
          if page&.status == 200
            attorney_links = @parser.attorney_links(page)
            attorneys = []
            attorney_links.each do |attorney_link|
              attorney_page = @scraper.page(attorney_link[:link])
              next if attorney_page&.status != 200
              attorneys << {link: attorney_link[:link], text: attorney_link[:text], body: attorney_page.body.to_s}
            end
            page_save(page, attorneys, url, case_id, 'J')
            drop_index = 0
          end
        end
        index += 1
      end
    end
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def page_save(page, attorneys, url, case_id, subfolder)
    raise if page.body.blank?
    content = "<p><b>data_source_url: </b><a class='original_link' href='#{url}'>#{url}</a></p>"
    content += "<div class='original_main'>#{page.body.to_s.force_encoding("UTF-8")}</div>"
    content += "<div class='original_attorneys'>"
    attorneys.each do |attorney|
      attorney_link = attorney[:link]
      attorney_text = attorney[:text]
      attorney_body = attorney[:body]
      attorney_class = Digest::MD5.hexdigest(attorney_link)
      content += "<div class='hash_#{attorney_class}'>"
      content += "<p><b>attorney_link: </b><span class='original_attorney_link'>#{attorney_link}</span></p>"
      content += "<p><b>attorney_text: </b><span class='original_attorney_text'>#{attorney_text}</span></p>"
      content += "<div class='original_attorney_body'>#{attorney_body}</div>"
      content += "</div>"
    end
    content +="</div>"
    name = "#{case_id}.html"
    peon.put(file: name, content: content, subfolder: subfolder)
    logger.info "PAGE SAVE! #{name}".blue
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def store
    @keeper.add_run('Store start!')
    run_id = @keeper.get_run
    index = 1
    folders = ['BD', 'DAR', 'FAR', 'J', 'OE', 'P', 'SJ', 'SJC', 'SJ_M']
    folders.each do |folder|
      files = peon.give_list(subfolder: folder)
      files.each do |file|
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: folder)
        info, add_info, activities, parties, documents = @parser.page_parse(page)
        @keeper.add_info(info, run_id, index)
        add_info.each do |item|
          @keeper.add_add_info(item, run_id)
        end
        activities.each do |activity|
          @keeper.add_activity(activity, run_id)
        end
        parties.each do |party|
          @keeper.add_party(party, run_id)
        end
        documents.each do |document|
          @keeper.add_document(document, info[:court_id], info[:case_id], run_id)
        end
        index += 1
        peon.move(file: file, from: folder)
      rescue StandardError => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
    @keeper.update_run('Store finish!')
    peon.throw_trash
    logger.info 'Store finish!'
    message_send('Store finish!')
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end
end

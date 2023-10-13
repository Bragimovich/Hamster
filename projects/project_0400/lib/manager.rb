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
    @saved = 1
  end

  def download(parts = false, arr = [])
    @keeper.add_run('Download start!') unless parts
    arr = ('A'..'Z') if arr.blank?
    arr.each do |fn_1|
      ('A'..'Z').each do |ln_1|
        first_name = fn_1
        last_name = ln_1
        @keeper.update_run("Download! First_name: #{first_name} | Last_name: #{last_name}")
        url = url(first_name, last_name)
        results, results_count = @scraper.get_items(url)
        logger.info "Search: first_name = `#{first_name}` | last_name = `#{last_name}`"
        logger.info "Results count: #{results_count}"
        if results_count >= 500
          ('A'..'Z').each do |fn_2|
            first_name = fn_1 + fn_2
            last_name = ln_1
            url = url(first_name, last_name)
            logger.info "Search: first_name = `#{first_name}`, last_name = `#{last_name}`"
            results, results_count = @scraper.get_items(url)
            logger.info "Results count: #{results_count}"
            if results_count >= 500
              ('A'..'Z').each do |ln_2|
                last_name = ln_1 + ln_2
                url = url(first_name, last_name)
                logger.info "Search: first_name = `#{first_name}`, last_name = `#{last_name}`"
                results, results_count = @scraper.get_items(url)
                logger.info "Results count: #{results_count}"
                page_save(results, fn_1)
              rescue => e
                message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
                logger.error message
              end
            else
              page_save(results, fn_1)
            end
          rescue => e
            message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
            logger.error message
          end
        else
          page_save(results, fn_1)
        end
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    logger.info 'Download finish!' unless parts
    @keeper.update_run('Download finish!') unless parts
    message_send('Download finish!') unless parts
  end

  def url(first_name, last_name)
    url = 'https://apps.calbar.ca.gov/attorney/LicenseeSearch/AdvancedSearch?'
    url += "LastNameOption=b&LastName=#{last_name}&FirstNameOption=b&FirstName=#{first_name}"
    url += '&MiddleNameOption=b&MiddleName=&FirmNameOption=b&FirmName=&CityOption=b&City='
    url += '&State=&Zip=&District=&County=&LegalSpecialty=&LanguageSpoken=&PracticeArea='
    url
  end

  def page_save(results, fn_1)
    results.each do |item|
      url = item[:link]
      name = item[:name]
      status = item[:status]
      number = item[:number]
      city = item[:city]
      admission_date = item[:admission_date]
      filename = "#{url.gsub(/\D+/, '')}.html"
      page = @scraper.page(url)
      content = "<p><b>data_source_url: </b><a class='original_link' href='#{url}'>#{url}</a></p>"
      content += "<p><b>name: </b><span class='original_name'>#{name}</span></p>"
      content += "<p><b>status: </b><span class='original_status'>#{status}</span></p>"
      content += "<p><b>number: </b><span class='original_number'>#{number}</span></p>"
      content += "<p><b>city: </b><span class='original_city'>#{city}</span></p>"
      content += "<p><b>admission_date: </b><span class='original_admission_date'>#{admission_date}</span></p>"
      raise if page.body.blank?
      content += page.body.to_s.force_encoding("UTF-8")
      peon.put(file: filename, subfolder: fn_1, content: content)
      logger.info "[#{@saved}] PAGE SAVE! #{filename}"
      @saved += 1
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def store(parts = false, arr = [], run = nil)
    @keeper.update_run('Store start!')
    run_id = run.blank? ? @keeper.get_run : run
    index = 1
    arr = ('A'..'Z') if arr.blank?
    arr.each do |subfolder|
      @keeper.update_run("store letter #{subfolder}!")
      files = peon.give_list(subfolder: subfolder)
      files.each do |file|
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: subfolder)
        info = @parser.info_parse(page)
        next if info.blank?
        @keeper.add_info(info, run_id, index)
        peon.move(file: file, from: subfolder)
        index += 1
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
      peon.throw_trash
    end
    @keeper.update_run('Store finish!') unless parts
    logger.info 'Store finish!' unless parts
    message_send('Store finish!') unless parts
  end

  def parts
    @keeper.add_run('Download start!')
    run_id = @keeper.get_run
    ('A'..'Z').each do |letter|
      download(true,[letter])
      store(true,[letter], run_id)
    end
    @keeper.update_run('Store finish!')
    logger.info 'Store finish!'
    message_send('Store finish!')
  end
end

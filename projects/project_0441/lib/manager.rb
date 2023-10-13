require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'
class Manager < Hamster::Scraper
  def download(options)
    scraper = Scraper.new
    year = options['year'].blank? ? Date.today.year - 2000 : options['year']
    formats = options['format'].blank? ? ['DF', 'DC', 'CC', 'CV', 'PR', 'TX'] : ["#{options['format']}"]
    formats.each do |format|
      (0..).each do |number|
        number_str = format('%03d', number)
        search_string = "#{format}-#{year}-#{number_str}*"
        cases = scraper.search_results(search_string)
        break if cases.blank?
        cases_save(cases)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
    message_send('Download finish!')
  end

  def cases_save(cases)
    scraper = Scraper.new
    cases.each do |cas|
      link = cas[:link]
      case_id = cas[:case_id]
      logger.info "#{case_id} - #{link}".blue
      begin
        page = scraper.page(link)
        file = "#{case_id.gsub('-','_').strip}.html"
        subfolder = case_id[0..1]
        peon.put(file: file, subfolder: subfolder, content: page.body)
        logger.info "File Save! #{subfolder}/#{file}".green
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
  end

  def store(options)
    parser = Parser.new
    keeper = Keeper.new
    keeper.add_run('store start!')
    run_id = keeper.get_run
    index = 1
    year = options['year'].blank? ? Date.today.year - 2000 : options['year']
    formats = options['format'].blank? ? ['DF', 'CV', 'PR', 'CC', 'DC', 'TX'] : ["#{options['format']}"]
    formats.each do |format|
      files = peon.give_list(subfolder: format)
      files = files.select{|item| item.include?("#{format}_#{year}") || item.include?("#{format}#{year}")}.sort
      files.each do |file|
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: format)
        case_info, parties, activities = parser.page_parse(page)
        keeper.add_case_info(case_info, index, run_id)
        keeper.add_parties(parties, run_id)
        keeper.add_activities(activities, run_id)
        peon.move(file: file, from: format, to: format)
        index += 1
      rescue StandardError => e
        if e.message.include?('These is an issue connecting') || e.message.include?("Can't connect to MySQL") || e.message.include?("MySQL client is not connected") || e.message.include?("Lost connection to MySQL server") || e.message.include?("Lock wait timeout exceeded")
          message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
          logger.error message
          sleep(600)
          retry
        else
          message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
          logger.error message
        end
      end
      peon.throw_trash
    end
    keeper.update_run('store finish!')
    message_send('Store finish!')
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end
end

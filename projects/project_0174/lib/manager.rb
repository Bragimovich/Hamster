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

  def download(options)
    year = options['year'].blank? ? "#{Date.today.year}" : "#{options['year']}"
    years = year == 'all' ? @scraper.years : [year]
    years.each do |year|
      links = @scraper.links(year)
      page_save(links, year)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    message_send('Download finish!')
    logger.info 'Download finish!'
  end

  def page_save(links, year)
    links.each do |link|
      name = Digest::MD5.hexdigest(link).to_s
      name += '.html'
      list = peon.give_list(subfolder: year)
      if list.include? "#{name}.gz"
        logger.info "FILE EXISTS! #{year} - #{name}".green
      else
        page = @scraper.page(link)
        content = "<p><b>data_source_url: </b><a class='original_link' href='#{link}'>#{link}</a></p>" + page.body
        peon.put(file: name, content: content, subfolder: year)
        logger.info "PAGE SAVE! #{year} - #{name}".blue
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def store(options)
    index = 1
    run_id = @keeper.get_run
    year = options['year'].blank? ? "#{Date.today.year}" : "#{options['year']}"
    years = year == 'all' ? @scraper.years : [year]
    years.each do |year|
      files = peon.give_list(subfolder: year.to_s)
      files.each do |file|
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: year.to_s)
        info = @parser.page_parse(page)
        @keeper.add_info(info, run_id, index) unless info.blank?
        peon.move(file: file, from: year.to_s)
        index += 1
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    peon.throw_trash
    message_send('Store finish!')
    logger.info 'Store finish!'
  end
end
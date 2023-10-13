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
    @sources = [
      {url: 'https://www.foreign.senate.gov/press/ranking', subfolder: 'ranking'},
      {url: 'https://www.foreign.senate.gov/press/chair', subfolder: 'chair'}
    ]
  end

  def download(options)
    pages = if options['pages'].blank?
              (1..1)
            else
              options['pages'] == 'all' ? (1..) : (1..options['pages'])
            end
    @sources.each do |source|
      url = source[:url]
      subfolder = source[:subfolder]
      pages.each do |page|
        links = @scraper.links(url, page)
        break if links.blank?
        page_save(links, subfolder)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
    message_send('Download finish!')
    logger.info 'Download finish!'
  end

  def page_save(links, subfolder)
    links.each do |link|
      name = Digest::MD5.hexdigest(link).to_s
      name += '.html'
      list = peon.give_list(subfolder: subfolder)
      if list.include? "#{name}.gz"
        logger.info "FILE EXISTS! #{name}".green
      else
        page = @scraper.page(link)
        content = "<p><b>data_source_url: </b><a class='original_link' href='#{link}'>#{link}</a></p>" + page.body
        peon.put(file: name, content: content, subfolder: subfolder)
        logger.info "PAGE SAVE! #{name}".blue
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def store
    @sources.each do |source|
      subfolder = source[:subfolder]
      run_id = subfolder == 'ranking' ? @keeper.get_run_ranking : @keeper.get_run_chair
      index = 1
      files = peon.give_list(subfolder: subfolder)
      files.each do |file|
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: subfolder)
        info = @parser.page_parse(page)
        if subfolder == 'ranking'
          @keeper.add_info_ranking(info, run_id, index) unless info.blank?
        else
          @keeper.add_info_chair(info, run_id, index) unless info.blank?
        end
        index += 1
        peon.move(file: file, from: subfolder)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
    peon.throw_trash
    message_send('Store finish!')
    logger.info 'Store finish!'
  end
end
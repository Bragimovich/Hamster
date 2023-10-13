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
    pages = if options['pages'].blank?
              (1..3)
            else
              options['pages'] == 'all' ? (1..) : (1..options['pages'])
            end
    pages.each do |page|
      links = @scraper.links(page)
      break if links.blank?
      page_save(links)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    message_send('Download finish!')
    logger.info 'Download finish!'
  end

  def page_save(links)
    links.each do |link|
      url = link[:link]
      title = link[:title]
      date = link[:date]
      name = Digest::MD5.hexdigest(url).to_s
      name += '.html'
      list = peon.give_list
      if list.include? "#{name}.gz"
        logger.info "FILE EXISTS! #{name}".green
      else
        page = @scraper.page(url)
        content = "<p><b>data_source_url: </b><a class='original_link' href='#{url}'>#{url}</a></p>"
        content += "<p><b>title: </b><span class='original_title'>#{title}</span></p>"
        content += "<p><b>date: </b><span class='original_date'>#{date}</span></p>"
        return if page.body.blank?
        content += page.body.to_s.force_encoding("UTF-8")
        peon.put(file: name, content: content)
        logger.info "PAGE SAVE! #{name}".blue
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def store
    @keeper.add_run('store start')
    index = 1
    files = peon.give_list
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      page = peon.give(file: file)
      info = @parser.page_parse(page)
      next if info[:date].to_s < '2022-12-15'
      @keeper.add_info(info, index) unless info.blank?
      index += 1
      peon.move(file: file)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    peon.throw_trash
    @keeper.update_run('store finish')
    message_send('Store finish!')
    logger.info 'Store finish!'
  end
end

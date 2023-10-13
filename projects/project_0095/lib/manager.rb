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
    items = @scraper.page_items
    items[0..50].each do |item|
      page_save(item)
    end
    message_send('Download finish!')
    logger.info 'Download finish!'
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def page_save(item)
    date = item[:date]
    title = item[:title]
    url = item[:url]
    release_no = item[:release_no]
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
      content += "<p><b>release_no: </b><span class='original_release_no'>#{release_no}</span></p>"
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

  def store
    @keeper.add_run('store start!')
    run_id = @keeper.get_run
    index = 1
    files = peon.give_list
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      page = peon.give(file: file)
      info = @parser.page_parse(page)
      @keeper.add_info(info, run_id, index) unless info.blank?
      peon.move(file: file)
      index += 1
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
    peon.throw_trash
    @keeper.update_run('store finish')
    message_send('Store finish!')
    logger.info 'Store finish!'
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end
end


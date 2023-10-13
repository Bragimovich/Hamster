require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def download(options)
    scraper = Scraper.new
    pages = if options['pages'].blank?
              (1..1)
            else
              options['pages'] == 'all' ? (1..) : (1..options['pages'])
            end
    pages.each do |page|
      links = scraper.links(page)
      break if links.blank?
      page_save(links)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    message_send('Download finish!')
  end

  def page_save(links)
    scraper = Scraper.new
    links.each do |link|
      url = link[:link]
      title = link[:title]
      date = link[:date]
      type = link[:type]
      name = Digest::MD5.hexdigest(url).to_s
      name += '.html'
      list = peon.give_list
      if list.include? "#{name}.gz"
        puts "FILE EXISTS! #{name}".green
      else
        page = scraper.page(url)
        content = "<p><b>data_source_url: </b><a class='original_link' href='#{url}'>#{url}</a></p>"
        content += "<p><b>title: </b><span class='original_title'>#{title}</span></p>"
        content += "<p><b>date: </b><span class='original_date'>#{date}</span></p>"
        content += "<p><b>type: </b><span class='original_type'>#{type}</span></p>"
        raise if page.body.blank?
        content += page.body.to_s.force_encoding("UTF-8")
        peon.put(file: name, content: content)
        puts "PAGE SAVE! #{name}".blue
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
  end

  def store
    parser = Parser.new
    keeper = Keeper.new
    run_id = keeper.get_run
    index = 1
    files = peon.give_list
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      page = peon.give(file: file)
      info, tags = parser.page_parse(page)
      keeper.add_info(info, run_id, index) unless info.blank?
      tags.each do |tag|
        keeper.add_tag(tag)
        tag_id = keeper.get_tag_id(tag)
        keeper.add_rel(tag_id, info[:link]) unless tag_id.blank?
      end
      index += 1
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    message_send('Store finish!')
  end
end

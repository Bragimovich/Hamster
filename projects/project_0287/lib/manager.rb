require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def download
    scraper = Scraper.new
    links = scraper.links
    page_save(links)
    message_send('Download finish!')
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end

  def page_save(links)
    scraper = Scraper.new
    links.each do |link|
      url = link[:link]
      title = link[:title]
      name = Digest::MD5.hexdigest(url).to_s
      name += '.html'
      list = peon.give_list
      if list.include? "#{name}.gz"
        puts "FILE EXISTS! #{name}".green
      else
        page = scraper.page(url)
        content = "<p><b>data_source_url: </b><a class='original_link' href='#{url}'>#{url}</a></p>"
        content += "<p><b>title: </b><span class='original_title'>#{title}</span></p>"
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
      info, bureau_offices, tags = parser.page_parse(page)
      keeper.add_info(info, run_id, index) unless info.blank?
      bureau_offices.each do |office|
        keeper.add_office(office, info[:link])
      end
      tags.each do |tag|
        keeper.add_tag(tag)
        tag_id = keeper.get_tag_id(tag)
        keeper.add_rel(tag_id, info[:link])
      end
      index += 1
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    message_send('Store finish!')
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end
end

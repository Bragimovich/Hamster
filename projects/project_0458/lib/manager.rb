require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def download(options)
    scraper = Scraper.new
    year = if options['year'].blank?
             Date.today.year
           else
             options['year']
           end
    links = scraper.links(year)
    page_save(links)
    peon.throw_temps
    peon.throw_trash
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
      date = link[:date]
      name = Digest::MD5.hexdigest(url).to_s
      name += '.html'
      list = peon.give_list
      if list.include? "#{name}.gz"
        puts "FILE EXISTS! #{name}".green
      else
        page = scraper.page(url)
        return if page.blank?
        content = "<p><b>data_source_url: </b><a class='original_link' href='#{url}'>#{url}</a></p>"
        content += "<p><b>title: </b><span class='original_title'>#{title}</span></p>"
        content += "<p><b>date: </b><span class='original_date'>#{date}</span></p>"
        content += "<p><b>release_no: </b><span class='original_release_no'>#{page[:release_no]}</span></p>"
        content += "<p><b>contact_info: </b><span class='original_contact_info'>#{page[:contact_info]}</span></p>"
        content += "<p><b>article: </b><span class='original_article'>#{page[:article]}</span></p>"
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
    keeper.add_run('store start!')
    run_id = keeper.get_run
    index = 1
    files = peon.give_list
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      page = peon.give(file: file)
      info = parser.page_parse(page)
      keeper.add_info(info, index, run_id) unless info.blank?
      index += 1
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    keeper.update_run('store finish')
    message_send('Store finish!')
  end
end


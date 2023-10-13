# frozen_string_literal: true

require_relative '../lib/parser'

class Scraper < Hamster::Harvester

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'judiciary.house.gov'
    @count_new = 0
  end

  def main(pages, page_start)
    links = links(pages, page_start)
    links_num = links.count
    index = 1
    links.each do |item|
      begin
        link = item
        name = link[link.index(/[^=]+?$/), link.length]
        name += '.html'

        list = peon.give_list
        if list.include? "#{name}.gz"
          puts "[#{index}/#{links_num}] FILE EXISTS! #{name}".green
        else
          page_save(link, name, index, links_num)
        end
        index += 1
      rescue StandardError => e
        message = "Page: [#{index}/#{links_num}] #{link} \nError: #{e.message}\nBacktrace:#{e.backtrace}".red
        puts message
        message_send(message)
      end
    end
    if @count_new > 0
      message = "Save #{@count_new} new pages.".green
    else
      message = "No new pages.".green
    end
    message_send(message)
    Parser.new.main
  end

  # PAGE SAVE

  def page_save(link, name, index, links_num)
    retry_count = 0
    begin
      hamster = Hamster.connect_to(link,
                                   headers: { 'Host': @host },
                                   proxy_filter: @proxy_filter,
                                   iteration: 9)
      page = hamster.body

      raise if hamster&.status != 200

      peon.put(file: name, content: page)
      puts "[#{index}/#{links_num}] PAGE SAVE! #{name}".blue
      @count_new += 1
    rescue StandardError
      if hamster&.status == 404 && retry_count > 5
        message = "PAGE: #{link}\nSTATUS #{hamster&.status}\n ERROR! PLEASE TAKE A LOOK!".red.underline
      elsif retry_count > 20
        message = "PAGE: #{link}\nSTATUS #{hamster&.status} FATAL ERROR! PLEASE CHECK!".red.underline
      else
        message = "PAGE: #{link}\nSTATUS #{hamster&.status} ERROR! RETRY! [#{retry_count}]".red.underline
        retry_count += 1
        retry
      end
      puts message
      message_send(message)
    end
  end

  # PAGE SAVE END

  # LINKS

  def links(pages, page_start)

    links = []

    (page_start..(page_start + pages)).each do |page_num|
      retry_count = 0
      begin
        url = "https://judiciary.house.gov/news/documentquery.aspx?DocumentTypeID=27&Page=#{page_num}"
        hamster = Hamster.connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
        page = Nokogiri::HTML.parse(hamster.body)
        content = page.css('#newsdoclist .newsblocker .news-texthold .newsie-titler a')
        raise if hamster&.status != 200
        break if content.empty?

        content.each do |item|
          url_part = item['href'].to_s

          page_url = "https://judiciary.house.gov/news/#{url_part}"

          puts "[#{links.count + 1}] #{page_url}"
          links << page_url
        end

      rescue StandardError
        if retry_count > 20
          message2 = "PAGE: #{url}\nSTATUS #{hamster&.status} FATAL ERROR! PLEASE CHECK!".red.underline
          puts message2
          message_send(message2)
        else
          message = "PAGE: #{url}\nSTATUS #{hamster&.status} ERROR! RETRY!".red.underline
          puts message
          message_send(message)
          retry_count += 1
          retry
        end
      end
    end

    links
  end

  # LINKS END

  def message_send(message)
    task_title = 'Scrape - #187'
    name_to = 'Igor Sas'
    Hamster.report(to: name_to, message: "#{task_title}\n#{message.uncolorize}")
  end
end
require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'

class Manager < Hamster::Scraper

  def initialize(**options)
    super
    @peon = Peon.new(storehouse)
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    
    scrape_for_main_pages if options[:scrape]
  end

  QUERY = '?page='

  def scrape_for_main_pages

    @md5_cash_maker = {
      :exim => MD5Hash.new(columns:%i[title teaser article with_table date link contact_info data_source_url])
    }

    number_page = 0

    loop do
      main_page_html = @scraper.main_page(QUERY + number_page.to_s)

      return if main_page_html.nil?

      if @parser.check_main_page(html: main_page_html)

        array_article_links_from_main_page = @parser.get_array_links_from_main_page(main_page_html)

        array_article_links_from_main_page.each do |link|
          if @keeper.existed_article(link).nil?
            article_page_html = @scraper.article_page(link)
            @peon.put(content: article_page_html, file: "#{link.to_s[26..].gsub(/[^A-Za-z0-9\-\$]/, '')}")
            article_page_html = @peon.give(file: "#{link.to_s[26..].gsub(/[^A-Za-z0-9\-\$]/, '')}")
            keeper(@parser.get_data(article_page_html, link))
          else
            @keeper.finish
            return
          end
        end
        number_page += 1
      else
        @keeper.finish
        break
      end
    end
  end

  def keeper(hash)
    return if hash.nil?

    hash[:md5_hash] = @md5_cash_maker[:exim].generate(hash)
    @keeper.save_data(hash)
  end

end


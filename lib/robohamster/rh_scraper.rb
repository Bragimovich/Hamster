# frozen_string_literal: true

class RoboHamsterScraper < Hamster::Scraper
  def initialize(*_)
    super
  end

  # START RoboHamster
  def robohamster(config_hash, update=nil)
    # Make from hash config class
    config = RoboHamsterConfigCompiler.new(config_hash)
    @update = update
    # Get array of hashes with data of elements
    array_of_elements = scrape(config)
  end

  private

  def scrape(config)
    url = config.url
    uri = URI(url)

    parser = RoboHamsterParser.new()

    db = RoboHamsterKeeper.new(config.database, config.column_in_table, config.column_types)

    md5_hashes_by_table = making_md5_hash(config.column_in_table)

    next_page_nokogiri = config.navigation
    elements_on_page = nil

    main_uri = uri.scheme + '://' + uri.host

    cobble = Dasher.new(:using=>:cobble, :redirect=>true)

    loop do

      index_page = cobble.get(url)
      array_of_elements_general = parser.get_elements_from_index(index_page, config.index)
      elements_on_page = array_of_elements_general.length if elements_on_page.nil?
      new_elements, existed_md5_hash = new_hashes(config)
      insert_count = 0
      existed_articles_on_page = 0
      array_of_elements_general.each do |element|
        next if element["link"].nil?
        element["link"] = main_uri + element["link"] if !element["link"].match(/^http/)

        page = cobble.get(element["link"])
        next if page.nil?
        config.column_in_table.each do |table_name, columns|
          new_elements[table_name].push(parser.get_element_page(page, config.page[table_name])) #TODO: if there are not pages for each element
          element.each do |column_name, value|
            new_elements[table_name][-1][column_name] = value if column_name.to_s.in?(columns)
          end
          element_md5_hash = md5_hashes_by_table[table_name].generate(new_elements[table_name][-1])
          new_elements[table_name][-1]["md5_hash"] = element_md5_hash
          existed_md5_hash[table_name].push(element_md5_hash)
        end
        insert_count += 1

        if insert_count>19 and elements_on_page>50
          insert_count = 0
          existed_rows = db.insert_in_all_tables(new_elements, existed_md5_hash)
          existed_articles_on_page += count_max_existed_articles_on_page(existed_rows)
          new_elements, existed_md5_hash = new_hashes(config)
        end
      end

      existed_rows = db.insert_in_all_tables(new_elements, existed_md5_hash)
      existed_articles_on_page += count_max_existed_articles_on_page(existed_rows)
      Hamster.logger.debug("Existed elements on page:#{existed_articles_on_page}")
      break if existed_articles_on_page>0 and @update

      if !next_page_nokogiri.nil?
        url = parser.next_page(index_page, next_page_nokogiri, url)
      else
        break
      end
      Hamster.logger.debug("element: #{elements_on_page}")

      break if array_of_elements_general.length<elements_on_page #TODO: get another length
    end
  end


  def making_md5_hash(column_in_table)
    md5_hashes_by_table = {}
    column_in_table.each do |table_name, columns|
      md5_hashes_by_table[table_name] = MD5Hash.new(:columns=>columns)
    end
    md5_hashes_by_table
  end

  def count_max_existed_articles_on_page(existed_md5_hash)
    max_existed_elements = 0
    existed_md5_hash.each do |table_name, existed_elements|
      max_existed_elements = existed_elements if max_existed_elements < existed_elements
    end
    max_existed_elements
  end

  def new_hashes(config)
    new_elements = {}
    existed_md5_hash = {}
    config.tables.each do |table|
      new_elements[table] = []
      existed_md5_hash[table] = []
    end
    [new_elements, existed_md5_hash]
  end
end
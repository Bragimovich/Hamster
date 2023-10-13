# frozen_string_literal: true

require_relative 'scrape_lake'
require_relative 'parse_lake'
require_relative 'store_lake'
require_relative 'db_lake'
require_relative 'logger_msg'


class ManagerLake < Hamster::Scraper
  attr_reader :options
  attr_reader :scrape_lake

  def initialize(options)
    super(options)
    @options = options
    @scrape_lake = ScrapeLake.new
    @parse_lake = ParseLake.new
    @store = StoreLake.new
    @logger_msg = LoggerMsg.new
    @db = DbLake.new
    @index_array = []


    begin
      @logger_msg.log_begin
      if @options[:update]
        update
      elsif @options[:download]
        download
      end

      @db.finish
      @logger_msg.log_success
    rescue StandardError => err
      pp err
      @db.finish_error
      @logger_msg.log_error
    end

  end

  def update
    @scrape_lake.callback_page_index = Proc.new { |content| @parse_lake.index_next_page(content) }
    @scrape_lake.download do |content|
      @index_array << @parse_lake.parse_index(content) if @parse_lake.content?(content)
    end
    @index_array.flatten!

    @scrape_lake.download_content(@index_array) do |index, content|
      @db.insert_index(index)
      @parse_lake.activities_callback = Proc.new { |content, func_cb|  @scrape_lake.next_page_content(content, func_cb) }
      hash_data = @parse_lake.parse_content(content)
      store_callback = Proc.new { |url| @scrape_lake.download_photo(url) }
      url_photo = @store.store_to_aws(hash_data, store_callback)
      hash_data[:aws_link] = url_photo
      @db.insert_content(index: index, content: hash_data)
    end


  end

  def download
    years = (@options[:year].nil?) ? DateTime.now.year - 2 : @options[:year]
    month = (@options[:month].nil?) ? DateTime.now.month : @options[:month]
    day = (@options[:day].nil?) ? DateTime.now.day : @options[:day]

    date_end = DateTime.parse("#{years}-#{month}-#{day}")
    begin
      date_begin = date_end
      date_end = date_begin + 20
      date_end = DateTime.now if date_end.to_date > DateTime.now.to_date
      @scrape_lake.date_from = date_begin
      @scrape_lake.date_to = date_end
      @index_array = []
      update
    end while date_end.to_date <= DateTime.now.to_date
  end

end

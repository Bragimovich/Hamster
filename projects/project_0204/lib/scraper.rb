# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @run_id = run
    @already_fetched_articles = UsDeptWaysAndMeans.pluck(:link)
  end

  def scrape
    count_page = get_pages_count
    (0..count_page).each do |num_page|
      url_main = "https://waysandmeans.house.gov/category/press-releases/?num=#{num_page}"
      page_list_teasers = connect_to(url_main)
      array_teasers = parse_list_teasers(page_list_teasers)
      data_array = []
      array_teasers.each do |general_info|
        retries = 0
        begin
         next if @already_fetched_articles.include? general_info[:link]
          page_article = connect_to(general_info[:link])
          other_teasers = parse_article(
            page_article,
            url_main
          )
        rescue => error
          retries += 1
          if retries > 3
            mess = "\nError: #{general_info[:link]}| #{error}"
            log mess, :red
            Hamster.report(to:'Raza Aslam', message: mess, use: :both)
            exit 0
          end
          retry
        end

        data_hash = general_info.merge(other_teasers)
        data_hash = mark_empty_as_nil(data_hash)

        data_array.push(data_hash)
        if data_array.count > 5
          insert_all data_array
          data_array = []
        end
      end
      begin
        insert_all data_array unless data_array.empty?
      rescue
        insert_all_each(data_array)
      end
    end
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end

  def insert_all(info)
    UsDeptWaysAndMeans.insert_all(info)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10
    response.body
  end

  def run
    RunId.new(UsDeptWaysAndMeansRuns)
  end

end

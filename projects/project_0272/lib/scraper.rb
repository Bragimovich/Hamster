class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
  end

  attr_reader :count

  def scrape
    links_db = keeper.all_links
    [%w[news-release s], %w[emergency-designation s], ['stakeholder-information', '']].each do |type|
      max_results = total_max = 300
      start_index = 0
      2.times do
        parsed    = get_json(max_results, start_index, total_max, type)
        links     = parsed['results'].map{ |i| "https://www.fsa.usda.gov#{i['folder']}#{i['name']}" }
        new_links = links.reject { |link| links_db.include?(link) }
        save_files(new_links)
        start_index += 300
        total_max   += 300
      end
    end
  end

  private

  attr_reader :keeper

  def save_files(links)
    links.each do |link|
      sleep(rand(0.2..0.5))
      article_page = get_body_of_page(link)
      md5          = MD5Hash.new(columns: %i[link])
      md5.generate({link: link})
      file_name = md5.hash
      peon.put(content: article_page, file: file_name)
      @count += 1
    end
  end

  def get_json(max_results, start_index, total_max, type)
    form_data = {
      "criteria": [
        "type = 'page'",
        "site = 'fsa.usda.gov'",
        "folder LIKE '/news-room/#{type.join}/%'",
        "dcterms:source = 'national-post-#{type.first}'"
      ],
      "isEditMode": "false",
      "maxResults": max_results,
      "orderBy": "dcterms:created desc, linktext_lower desc",
      "returnTotalEntries": true,
      "startIndex": start_index,
      "totalMaxResults": total_max
    }.to_json

    json = connect_to(url:          'https://dts.fsa.usda.gov/perc-metadata-services/metadata/get',
                      proxy_filter: @proxy_filter,
                      ssl_verify:   false,
                      method:       :post,
                      req_body:     form_data,
                      headers:      { Content_Type: 'application/json' })

    JSON.parse(json&.body)
  end

  def get_body_of_page(link)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false)&.body
  end
end

# frozen_string_literal: true
class Parser < Hamster::Parser
  URL = 'https://markets.ft.com'
  
  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end
  
  def price_parsing(response)
    page       = parse_page(response)
    page_part  = page.css('div.mod-tearsheet-overview__quote')
    return nil if page_part.empty?

    date       = check_parse(page_part)
    data_hash  = parse(date, page, page_part) unless date.nil?     
  end

  def get_equities_url(response)
    page           = parse_page(response)
    url_array      = []
    country_array  = []
    exchange_array = []
    return if page.css("div[data-module-name='ResultsApp']").first.text.include? 'no results found'

    equity_tab_idx = find_equity_tab_index(page)
    return if equity_tab_idx.nil?

    records = page.css('table.mod-ui-table')[equity_tab_idx].css('tbody tr') rescue return
    return if records.empty?

    records.each do |record|
      equity_url = URL + record.css('a')[0]["href"]
      country    = record.css('td').last.text.strip
      exchange   = record.css('td')[2].text.strip
      url_array.push(equity_url)
      country_array.push(country)
      exchange_array.push(exchange)
    end
    [url_array, country_array, exchange_array]
  end

  def parse_equities(response, data_source_url, link, country, exchange)
    page      = parse_page(response)
    info      = page.css('div.mod-tearsheet-overview__esi').first.children rescue nil
    sector    = info.first.text.strip rescue nil
    industry  = info.last.text.strip rescue nil
    data_hash = {
      equity_name: page.css('.mod-tearsheet-overview__header__name--large').text,
      equity_url: link,
      equity_symbol: link.split('=').last,
      country: country,
      exchange: exchange,
      sector: sector,
      industry: industry,
      data_source_url: data_source_url
    }
    data_hash
  end

  def parse(date, page, page_part)
    data_hash = {}
    data_hash["data_as_of"]        = (date)
    data_hash["date_string"]       = page_part.css('div.mod-tearsheet-overview__quote div').text.strip rescue '-'
    data_hash["equity_symbol"]     = page.css('span.mod-ui-symbol-chain__trigger').first.text.strip rescue nil
    return nil if data_hash["equity_symbol"].nil?
    five_yr_beta                   = fetch_info(page_part, 4)
    price_usd                      = fetch_info(page_part, 0)
    shares_traded                  = fetch_info(page_part, 2)
    yearly_change_pct              = fetch_info(page_part, 3).gsub('%', '').strip rescue nil
    data_hash["5yr_beta"]          = five_yr_beta      == '' ? nil : five_yr_beta.gsub(',','')
    data_hash["price_usd"]         = price_usd         == '' ? nil : price_usd.gsub(',', '')
    data_hash["shares_traded"]     = shares_traded     == '' ? nil : shares_traded
    data_hash["yearly_change_pct"] = yearly_change_pct == '' ? nil : yearly_change_pct
    key_stats                      = page.css("div[data-f2-app-id ='mod-tearsheet-key-stats'] div.mod-tearsheet-key-stats__data tr")
    unless key_stats.empty?
      data_hash["open"]                   = find_stats(key_stats, 'open')
      data_hash["high"]                   = find_stats(key_stats, 'high')
      data_hash["low"]                    = find_stats(key_stats, 'low')
      data_hash["bid"]                    = find_stats(key_stats, 'bid')
      data_hash["offer"]                  = find_stats(key_stats, 'offer')
      data_hash["prev_close"]             = find_stats(key_stats, 'previous close')
      data_hash["avg_volume"]             = find_stats(key_stats, 'average volume')
      data_hash["shares_outstanding"]     = find_stats(key_stats, 'shares outstanding')
      data_hash["free_float"]             = find_stats(key_stats, 'free float')
      data_hash["price_earnings_ratio"]   = find_stats(key_stats, 'p/e (ttm)')
      data_hash["market_cap_usd"]         = find_stats(key_stats, 'market cap')
      data_hash["earnings_per_share_usd"] = find_stats(key_stats, 'eps (ttm)')
    end
    if key_stats.empty?
      data_hash["open"], data_hash["high"], data_hash["low"], data_hash["bid"], data_hash["offer"], data_hash["prev_close"], data_hash["avg_volume"], data_hash["shares_outstanding"], data_hash["free_float"], data_hash["price_earnings_ratio"], data_hash["market_cap_usd"], data_hash["earnings_per_share_usd"] = nil
    end
    low_high = page.css('div.mod-ui-range-bar__container__labels')
    unless low_high.empty?
      data_hash["52_wk_min_price"]      = low_high.first.css("span.mod-ui-range-bar__container__label--lo span.mod-ui-range-bar__container__value").text.strip
      low_date                          = low_high.first.css("span.mod-ui-range-bar__container__label--lo span[2]").text.strip
      data_hash["52_wk_min_price_date"] = Date.parse(low_date).to_date rescue nil
      data_hash["52_wk_max_price"]      = low_high.first.css("span.mod-ui-range-bar__container__label--hi span.mod-ui-range-bar__container__value").text.strip
      high_date                         = low_high.first.css("span.mod-ui-range-bar__container__label--hi span[2]").text.strip
      data_hash["52_wk_max_price_date"] = Date.parse(high_date).to_date rescue nil
    end
    if low_high.empty?
      data_hash["52_wk_min_price"], data_hash["52_wk_min_price_date"], data_hash["52_wk_max_price"], data_hash["52_wk_max_price_date"] = nil
    end
    data_hash["data_source_url"]  = URL + page.css(".mod-ui-overlay__content ul li a")[0]["href"].gsub(' ', '%20') rescue nil
    data_hash
  end

  def fetch_info(page_part, index)
    page_part.css('li')[index].css('span')[1].text.gsub('--', '').strip rescue nil
  end

  def parse_info(response)
    page       = parse_page(response)
    about_data = page.css("div[data-module-name='AboutTheCompanyApp']").first rescue nil
    return {} if about_data.nil?
    data_hash                      = {}
    data_hash["about"]             = about_data.css('p.mod-tearsheet-profile-description.mod-tearsheet-profile-section').text.strip
    currancy_revenue               = find_currancy(about_data, 'Revenue in')
    currancy_income                = find_currancy(about_data, 'Net income in')
    revenue                        = find_about_data(about_data, 'Revenue in')
    net_income                     = find_about_data(about_data, 'Net income in')
    data_hash["revenue_usd"]       = revenue.nil? ? nil : "#{revenue} #{currancy_revenue}"
    data_hash["net_income_usd"]    = net_income.nil? ? nil : "#{net_income} #{currancy_income}"
    url_part                       = page.css(".mod-ui-naviTabs li a")[0]["href"]
    data_hash["incorporated_year"] = find_about_data(about_data, 'Incorporated').to_i rescue nil
    data_hash["employees_count"]   = find_about_data(about_data, 'Employee')
    value                          = find_address(about_data, 'Location')
    data_hash["location_raw"]      = value[0]
    data_hash["phone"]             = find_about_data(about_data, 'Phone')
    data_hash["fax"]               = find_about_data(about_data, 'Fax')
    data_hash["website"]           = find_about_data(about_data, 'Website')
    data_hash["equity_symbol"]     = url_part.split('=').last.strip
    data_hash["data_source_url"]   = URL + page.css(".mod-ui-overlay__content ul li a")[0]["href"].gsub(' ', '%20').gsub('summary', 'profile')
    data_hash["location_address"]  = value[1]
    data_hash["location_city"]     = value[2]
    data_hash["location_zip"]      = value[3]
    data_hash
  end

  private

  def find_stats(key_stats, word)
    value = key_stats.select{|s| s.css('th').text.downcase.strip == word}[0].css('td').text.gsub('--', '').gsub(',', '').strip
    value.squish.empty? ? nil : value
  end

  def check_parse(page_part)
    date  = page_part.css("div").text.split('as of')[-1].strip
    (date == 'Data delayed at least 15 minutes.') || ((Date.today - Date.parse(date)).to_i > 7)? nil : (date.include? 'BST') ?  DateTime.parse(date) - 1.hours : DateTime.parse(date) rescue nil
  end

  def find_equity_tab_index(document)
    equity_tab_idx = 0
    tabs           = document.css("ul[role='tablist'] li")
    if tabs.empty?
      if document.css("div[data-module-name='ResultsApp'] h2.mod-ui-header--event.o-teaser-collection__heading.o-teaser-collection__heading--half-width").first.text.include? 'Equitie'
        return equity_tab_idx
      else 
        return nil
      end
    else
      tabs.each_with_index do |tab, idx|
        if tab.text.include? 'Equities'
          equity_tab_idx = idx
          break

        end
      end
    end
    equity_tab_idx
  end

  def find_about_data(about_data, word)
    value = about_data.css('li').select { |e| e.css('.mod-ui-data-list__label').text.include? word }[0].css('.mod-ui-data-list__value').text.gsub('--','').strip rescue nil
    (value.nil? or value.empty?)? nil : value
  end

  def find_currancy(about_data, word)
    about_data.css('li').select{|e| e.css('.mod-ui-data-list__label').text.include? word}[0].css('.mod-ui-data-list__label').text.split('(').first.split.last.strip
  end

  def find_address(about_data, word)
    li               = about_data.css('li').select{|e| e.css('.mod-ui-data-list__label').text.include? word}[0]
    info             = li.css('address').first.css('*').map { |e| e.text.strip }
    location_raw     = info.reject { |e| e == '' or e == '0' or e == '0 000000' }.join("\n").strip rescue nil
    location_address = info[1..-4].reject { |e| e == '' or e == '0' or e == '0 000000' }.join(" ").strip
    city_zip         = li.css('address').first.css('*')[-3].text.strip.split
    zip_flag         = false
    location_city    = []
    location_zip     = []
    city_zip.each do |czword|
      if czword.scan(/\d+/).first.nil? and !zip_flag
        location_city.push(czword)
      else
        zip_flag = true
        location_zip.push(czword)
      end
    end
    location_city  = location_city.empty? ? nil : location_city.join(" ")
    unless location_zip.empty?
      location_zip = location_zip.join(' ')
      location_zip = location_zip == '0 000000' ? nil : location_zip
    else
      location_zip = nil
    end
    [location_raw, location_address, location_city, location_zip]
  end
end

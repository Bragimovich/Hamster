require_relative 'g_auth'
require 'zlib'
require 'stringio'
require_relative '../model/google_console_data'
require_relative '../model/google_console_data_top_page'
require_relative '../model/google_console_data_top_query'

class GParam
  attr_reader :code, :media, :credentials
  attr_writer :start_date, :end_date, :credentials, :run_id, :media, :code
  API_URL_SITE = "https://www.googleapis.com/webmasters/v3/sites"
  API_URL_QUERY = "https://www.googleapis.com/webmasters/v3/sites/%s/searchAnalytics/query"
  API_URL_SITEMAP = "https://www.googleapis.com/webmasters/v3/sites/%s/sitemaps"

  def initialize
    super
    @auth = []
    @params = []


    @sites = []
    @credentials = nil

    # token = Storage.new


    # puts "Run telegramm_bot"
  end

  # TODO: New functional

  def report message
    Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
  end

  def header
    {
      "Authorization" => "Bearer "+ (( @credentials.nil? ) ? "" : @credentials.access_token).to_s,
      "Host" => "www.googleapis.com",
      "Accept-Encoding" => "gzip",
      "User-Agent" => @media,
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  end

  def sites
    response = Faraday.get(API_URL_SITE, {}, header)
    gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
    src_sites = JSON.parse(gz.read)
    if src_sites["error"].nil?
      sites = src_sites["siteEntry"]
      sites.each do |site|
        url = site["siteUrl"]
        if ( rec = GoogleConsoleData.find_by(run_id: @run_id, url: url, name: @media) ).nil?
          rec = GoogleConsoleData.new
          rec.run_id = @run_id
          rec.url = url
          rec.name = @media
          rec.save
        end
      end
      return true
    else
      report @media +": " + src_sites["error"].to_s
      return false
    end
  end


  def params_is_zero
    records = GoogleConsoleData.where("click_total = 0 AND impressions_total = 0 AND name = '#{@media}'")
    records.each do |rec|

      begin
      gruns = rec.gruns
      @run_id = rec.run_id
      @start_date = gruns.start_date
      @end_date = gruns.end_date

      url = rec.url
      url_query = sprintf(API_URL_SITEMAP, CGI::escape(url))
      url_perform = sprintf(API_URL_QUERY, CGI::escape(url))
      discovery_url = sitemap_api(url_query)
      next if discovery_url.nil?
      clicks, impressions, ctr, position = performens(url_perform)
      string = (discovery_url.to_s + clicks.to_s + impressions.to_s + ctr.to_s + position.to_s + url + @media).to_s
      md5_hash = Digest::MD5.hexdigest string

      rec.discovered_url = discovery_url
      rec.click_total = clicks
      rec.impressions_total = impressions
      rec.ctr = ctr
      rec.position = position
      rec.start_date = Date.parse(@start_date)
      rec.end_date = Date.parse(@end_date)
      rec.md5_hash = md5_hash
      rec.save
      rescue
        next
      end
      #TEST
      # return true
      #
      # top_q = top_queries url_perform
      # top_q.each do |item|
      #   item.merge!({
      #     :site_id => rec.id.to_s,
      #     :run_id => @run_id,
      #     :name => @media,
      #     :start_date =>  Date.parse(@start_date),
      #     :end_date => Date.parse(@end_date),
      #     :md5_hash => Digest::MD5.hexdigest(item.to_s)
      #   })
      #
      #   if GoogleConsoleDataTopQuery.find_by(md5_hash: item[:md5_hash], name: @media).nil?
      #     GoogleConsoleDataTopQuery.create(item)
      #   end
      # end unless top_q.nil?
      #
      # top_p = top_pages url_perform
      #
      # top_p.each do |item|
      #           i = {
      #                 :site_id => rec.id.to_s,
      #                 :run_id => @run_id,
      #                 :name => @media,
      #                 :start_date =>  Date.parse(@start_date),
      #                 :end_date => Date.parse(@end_date),
      #                 :md5_hash => Digest::MD5.hexdigest(item.to_s),
      #                 :url => item[:key],
      #                 :click_total => item[:click_total],
      #                 :impressions_total => item[:impressions_total],
      #                 :ctr => item[:ctr],
      #                 :position => item[:position]
      #               }
      #   if GoogleConsoleDataTopPage.find_by(md5_hash: i[:md5_hash], name: @media).nil?
      #     GoogleConsoleDataTopPage.create(i)
      #   end
      # end unless top_p.nil?
    end

    return true
  end

  def params_is_null
    records = GoogleConsoleData.where("click_total IS NULL AND impressions_total IS NULL AND name = '#{@media}'")
    records.each do |rec|
      begin
      gruns = rec.gruns
      @run_id = rec.run_id
      @start_date = gruns.start_date
      @end_date = gruns.end_date

      url = rec.url
      url_query = sprintf(API_URL_SITEMAP, CGI::escape(url))
      url_perform = sprintf(API_URL_QUERY, CGI::escape(url))
      discovery_url = sitemap_api(url_query)
      next if discovery_url.nil?
      clicks, impressions, ctr, position = performens(url_perform)
      string = (discovery_url.to_s + clicks.to_s + impressions.to_s + ctr.to_s + position.to_s + url + @media).to_s
      md5_hash = Digest::MD5.hexdigest string

      rec.discovered_url = discovery_url
      rec.click_total = clicks
      rec.impressions_total = impressions
      rec.ctr = ctr
      rec.position = position
      rec.start_date = Date.parse(@start_date)
      rec.end_date = Date.parse(@end_date)
      rec.md5_hash = md5_hash
      rec.save
      rescue
        next
      end
      #TEST
      # return true
      #
      # top_q = top_queries url_perform
      # top_q.each do |item|
      #   item.merge!({
      #     :site_id => rec.id.to_s,
      #     :run_id => @run_id,
      #     :name => @media,
      #     :start_date =>  Date.parse(@start_date),
      #     :end_date => Date.parse(@end_date),
      #     :md5_hash => Digest::MD5.hexdigest(item.to_s)
      #   })
      #
      #   if GoogleConsoleDataTopQuery.find_by(md5_hash: item[:md5_hash], name: @media).nil?
      #     GoogleConsoleDataTopQuery.create(item)
      #   end
      # end unless top_q.nil?
      #
      # top_p = top_pages url_perform
      #
      # top_p.each do |item|
      #           i = {
      #                 :site_id => rec.id.to_s,
      #                 :run_id => @run_id,
      #                 :name => @media,
      #                 :start_date =>  Date.parse(@start_date),
      #                 :end_date => Date.parse(@end_date),
      #                 :md5_hash => Digest::MD5.hexdigest(item.to_s),
      #                 :url => item[:key],
      #                 :click_total => item[:click_total],
      #                 :impressions_total => item[:impressions_total],
      #                 :ctr => item[:ctr],
      #                 :position => item[:position]
      #               }
      #   if GoogleConsoleDataTopPage.find_by(md5_hash: i[:md5_hash], name: @media).nil?
      #     GoogleConsoleDataTopPage.create(i)
      #   end
      # end unless top_p.nil?
    end

    return true
  end


  def params
    records = GoogleConsoleData.where(run_id: @run_id, name: @media, md5_hash: nil)
    records.each do |rec|
      url = rec.url
      url_query = sprintf(API_URL_SITEMAP, CGI::escape(url))
      url_perform = sprintf(API_URL_QUERY, CGI::escape(url))
      discovery_url = sitemap_api(url_query)
      next if discovery_url.nil?
      clicks, impressions, ctr, position = performens(url_perform)
      string = (discovery_url.to_s + clicks.to_s + impressions.to_s + ctr.to_s + position.to_s + url + @media).to_s
      md5_hash = Digest::MD5.hexdigest string

      rec.discovered_url = discovery_url
      rec.click_total = clicks
      rec.impressions_total = impressions
      rec.ctr = ctr
      rec.position = position
      rec.start_date = Date.parse(@start_date)
      rec.end_date = Date.parse(@end_date)
      rec.md5_hash = md5_hash
      rec.save

      #TEST
      # return true
      #
      # top_q = top_queries url_perform
      # top_q.each do |item|
      #   item.merge!({
      #     :site_id => rec.id.to_s,
      #     :run_id => @run_id,
      #     :name => @media,
      #     :start_date =>  Date.parse(@start_date),
      #     :end_date => Date.parse(@end_date),
      #     :md5_hash => Digest::MD5.hexdigest(item.to_s)
      #   })
      #
      #   if GoogleConsoleDataTopQuery.find_by(md5_hash: item[:md5_hash], name: @media).nil?
      #     GoogleConsoleDataTopQuery.create(item)
      #   end
      # end unless top_q.nil?
      #
      # top_p = top_pages url_perform
      #
      # top_p.each do |item|
      #           i = {
      #                 :site_id => rec.id.to_s,
      #                 :run_id => @run_id,
      #                 :name => @media,
      #                 :start_date =>  Date.parse(@start_date),
      #                 :end_date => Date.parse(@end_date),
      #                 :md5_hash => Digest::MD5.hexdigest(item.to_s),
      #                 :url => item[:key],
      #                 :click_total => item[:click_total],
      #                 :impressions_total => item[:impressions_total],
      #                 :ctr => item[:ctr],
      #                 :position => item[:position]
      #               }
      #   if GoogleConsoleDataTopPage.find_by(md5_hash: i[:md5_hash], name: @media).nil?
      #     GoogleConsoleDataTopPage.create(i)
      #   end
      # end unless top_p.nil?
    end

    return true
  end


  def error_function param
    code = param["error"]["code"]
    message = param["error"]["message"].to_s
    if code == 403
      report (@media +" "+@start_date.to_s+" "+code.to_s+" "+ message).to_s
      return true
    elsif code == 401
      report (@media +" "+@start_date.to_s+" "+code.to_s + message).to_s
      raise (@media +" "+@start_date.to_s+" "+code.to_s + message).to_s
    else
      report (@media +" "+@start_date.to_s+" "+code.to_s + message).to_s
      return true
    end
    return false
  end

  def sitemap_api url
    response = Faraday.get(url, {}, header)
    gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
    param = JSON.parse(gz.read)

    flag = error_function(param) unless param["error"].nil?
    return nil if flag

    contents = (!param["sitemap"].nil?) ? param["sitemap"].first["contents"] : nil
    discovery_url = contents.map { |i| i["submitted"].to_i }.inject(0, :+) unless contents.nil?
    discovery_url
  end

  def performens url
    # - Total Clicks
    # - Total Impressions
    response = Faraday.post(url, '{"startDate": "' + @start_date + '", "endDate": "' + @end_date + '"}', header)
    gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
    param = JSON.parse(gz.read)
    item = param["rows"]
    raise "Return nil:JSON, Auth error!" unless param["error"].nil?
    clicks = (item.nil?) ? "0" : item.first["clicks"]
    impressions = (item.nil?) ? "0" : item.first["impressions"]
    ctr = (item.nil?) ? "0" : item.first["ctr"]
    position = (item.nil?) ? "0" : item.first["position"]
    [clicks, impressions, ctr, position]
  end

  def top_tmp (**args)
    response = args[:response]
    gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
    param = JSON.parse(gz.read)
    top_r = param["rows"]
    top_r.map do |item|
          {
            :key => item["keys"].first,
            :click_total => item["clicks"],
            :impressions_total => item["impressions"],
            :ctr => item["ctr"],
            :position => item["position"]
          }
    end unless top_r.nil?
  end

  def top_queries url
    response = Faraday.post(url, '{"startDate":"' + @start_date + '","endDate":"' + @end_date + '","rowLimit":10,"dimensions":["QUERY"]}', header)
    top_tmp(response: response)
  end

  def top_pages url
    response = Faraday.post(url, '{"startDate":"' + @start_date + '","endDate":"' + @end_date + '","rowLimit":10,"dimensions":["PAGE"]}', header)
    top_tmp(response: response)
  end
  # TODO: End "New functional"
  #
  #

  def get_auth (**args)
    error = args[:error].nil? ? false : args[:error]
    media = args[:media].nil? ? false : args[:media]

    @client_auth_file.each do |file|
      v_auth = auth file
      @auth.push(v_auth)
    end
  end

  def get_sites
    @auth.each do |i|
      response = Faraday.get(API_URL_SITE, {}, i.get_header)
      gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
      src_sites = JSON.parse(gz.read)
      if src_sites["error"].nil?
        sites = src_sites["siteEntry"]
        o = { name: i.name,
              sites: sites,
              header: i.get_header }
        @sites.push(o)
      else
        get_auth({ error: true })
      end
    end
  end


  def save_db item, obj

    rec = GoogleConsoleData.new do |data|
      data.name = obj[:name]
      data.url = item[:url]
      data.discovered_url = (item[:contents].map { |i| i["submitted"].to_i }.inject(0, :+)) unless item[:contents].nil?
      data.click_total = (item[:perfermens].nil?) ? "0" : item[:perfermens].first["clicks"]
      data.impressions_total = (item[:perfermens].nil?) ? "0" : item[:perfermens].first["impressions"]
      data.ctr = (item[:perfermens].nil?) ? "0" : item[:perfermens].first["ctr"]
      data.position = (item[:perfermens].nil?) ? "0" : item[:perfermens].first["position"]
      data.start_date = Date.parse(@start_date)
      data.end_date = Date.parse(@end_date)
    end
    rec.save
    id_rec = rec.id

    unless item[:top_page].nil?
      item[:top_page].each do |page|
        data2 = GoogleConsoleDataTopPage.new do |data|
          data.site_id = id_rec
          data.name = obj[:name]
          data.url = page["keys"].first
          data.click_total = page["clicks"]
          data.impressions_total = page["impressions"]
          data.ctr = page["ctr"]
          data.position = page["position"]
          data.start_date = Date.parse(@start_date)
          data.end_date = Date.parse(@end_date)
        end
        data2.save
      end
    end

    unless item[:top_query].nil?
      item[:top_query].each do |page|
        data2 = GoogleConsoleDataTopQuery.new do |data|
          data.site_id = id_rec
          data.name = obj[:name]
          data.key = page["keys"].first
          data.click_total = page["clicks"]
          data.impressions_total = page["impressions"]
          data.ctr = page["ctr"]
          data.position = page["position"]
          data.start_date = Date.parse(@start_date)
          data.end_date = Date.parse(@end_date)
        end
        data2.save
      end
    end
  end

  def top_query url, headers
    response = Faraday.post(url, '{"startDate":"' + @start_date + '","endDate":"' + @end_date + '","rowLimit":10,"dimensions":["QUERY"]}', headers)
    gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
    JSON.parse(gz.read)
  end

  def top_page url, headers
    response = Faraday.post(url, '{"startDate":"' + @start_date + '","endDate":"' + @end_date + '","rowLimit":10,"dimensions":["PAGE"]}', headers)
    gz = Zlib::GzipReader.new(StringIO.new(response.body.to_s))
    JSON.parse(gz.read)
  end
end

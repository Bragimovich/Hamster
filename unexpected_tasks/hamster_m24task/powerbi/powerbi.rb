require_relative '../model/google_console_data'
require_relative '../model/google_console_data_top_page'
require_relative '../model/google_console_data_top_query'

class PowerBiReports

  URL_SCOPE = "https://analysis.windows.net/powerbi/api/.default"
  AUTH_ID = "5b583476-5445-4afe-a2ff-c637d899fa6f"
  SECRET_ID = "im27Q~4zA773ZqwyFBdXlloAX25.G-NG5iuMs"
  GRANT_TYPE = "client_credentials"
  TENANT= "7a6dd497-bfc0-4569-aef2-b493ce2b94b5"
  GROUP_ID = "afd4f65a-915a-4dc4-8a6a-aade9b469f1f"
  #url api power bi
  private
  def name_comp? name
    @files_json.find {|item| item[:table] === name }
  end

  def add_dataset_id_in_files(id, name)
    @files_json.map! do |item|
      item.merge ({ id: (item[:table] === name)? id : item[:id] })
    end
  end

  public
  def initialize config
    @configure = config
    @tenant = config[:tenant]
    @group_id = config[:group_id]

    @url_login = "https://login.microsoftonline.com/#{@tenant}/oauth2/v2.0/token"
    @create_dataset = "https://api.powerbi.com/v1.0/myorg/groups/#{@group_id}/datasets"
    @get_datasets = "https://api.powerbi.com/v1.0/myorg/groups/#{@group_id}/datasets"
  end

  def report message
    Hamster.report(to: "Mikhail Golovanov", message: message, use: :slack)
  end
  #  тут косяк после создания таблинц надо бы их в переменных идентифицировать
  def create_tables obj
    result = query_post(@create_dataset, obj[:content])
    add_dataset_id_in_files(result["id"], result["name"])
  end

  def dataset_access
    resp = query_get(@get_datasets)
    resp["value"].each {|item| add_dataset_id_in_files(item["id"], item["name"])} unless resp["value"].nil? || resp["value"].empty?
  end

  def dataset_tables dataset_id
    api_tables = "https://api.powerbi.com/v1.0/myorg/datasets/#{dataset_id}/tables"
    resp = query_get(api_tables)
    resp["value"].map { |item| item["name"] }
  end

  def dataset_exists? name
    datasets = dataset_access
    @dataset = nil
    @tables = nil

    datasets.each { |item| @dataset = item if item["name"] === name } unless datasets.nil?

    if !@dataset.nil?
      dataset_id = @dataset["id"]
      tables = dataset_tables(dataset_id)
      if !tables.empty?
        @tables = tables
      end
    end
    !(@dataset.nil? || @tables.nil?)
  end

  def check_last_record

  end

  def token_expired
    telegram_token
  end

  def error_resp(body)
    unless body.empty?
      error = JSON.parse(body)
      unless error["error"].nil?
        code = error["error"]["code"]
        case code
        when "TokenExpired"
          token_expired
          raise "TokenExpired"
        end
      end
    end
  end

  def query_post (url_api, obj)
    ret = 5
    begin
      resp = Faraday.post(url_api) do |req|
        req.headers["Authorization"] = "#{@auth_data["token_type"]} #{@auth_data["access_token"]}"
        req.headers["Content-type"] = "application/json"
        req.body = obj
      end

      body = resp.body.force_encoding("UTF-8")
          if body[0].ord == 65279
            body = body[1..-1]
          end unless body.empty?
      unless body.nil? || body.empty?
          body = JSON.parse(body)
          if !body["error"].nil?
            raise "TokenExpired" if body["error"]["code"].match?("TokenExpired")
          end
      end

    rescue StandardError => err
      puts body
      pp err
      auth
      retry if (ret-=1 ) > 0
    end

    body
  end

  def auth
    response = Faraday.post(@url_login) do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      request = {
                  client_id: @configure[:client_id],
                  scope: @configure[:scope],
                  client_secret: @configure[:secret],
                  grant_type: @configure[:grant_type]
                }
      req.body = request.map { |key, value| key.to_s + "=" + CGI.escape(value.to_s) }.join("&")
    end

    # Add Error function
    @auth_data = JSON.parse(response.body)
  end

  def query_get (url_api)
    ret = 5
    begin
    resp = Faraday.get(url_api) do |req|
      req.headers["Authorization"] = "#{@auth_data["token_type"]} #{@auth_data["access_token"]}"
    end

    body = JSON.parse(resp.body)
    if !body["error"].nil?
      raise "TokenExpired" if body["error"]["code"].match?("TokenExpired")
    end

    rescue StandardError => err
      auth
      retry if (ret-=1 ) > 0
    end
    body
  end

  def post_rows(rows, dataset_id, table_name)
    sleep 0.5
    api_url = "https://api.powerbi.com/v1.0/myorg/groups/#{@group_id}/datasets/#{dataset_id}/tables/#{table_name}/rows"
    data = "{\"rows\": #{rows} }"
    query_post(api_url, data)
  end

  def query_execute(dataset_id, queries)
    api_query = "https://api.powerbi.com/v1.0/myorg/datasets/#{dataset_id}/executeQueries"
    query = queries.to_json
    query_post(api_query, query)
  end

  def id_last(item)
    dataset_id = item[:id]
    queries = { queries: [{ query: "EVALUATE { MAX ( data[start_date] ) }" }] }
    result = query_execute(dataset_id, queries)

    if (result["results"].first["tables"].size > 0)
      return (result["results"].first["tables"].first["rows"].first.empty?)? 0 : result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end

  def data_db_thread item_files
    offset = 0
    limit = 500

    start_id = id_last(item_files)
    start_id = 0 if start_id.nil?

    dataset_id = item_files[:id]
    media = (item_files[:table] === "analitycs" )? "analitics1" : item_files[:table]
    # start_date = Date.today() << 2

    while (res = GoogleConsoleData.select("id, name, url, discovered_url, click_total, impressions_total, ctr, position, start_date").where(name: media).where("start_date > ?", start_id).limit(limit).offset(offset)).size > 0
      table_data = ""
      table_data_query = []
      table_data_page = []

      table_data = res.map do |data|
        table_data_page << data.toppage.select("site_id, name, url, click_total, impressions_total, ctr, position, start_date").map { |item| { site_id: item.site_id, name: item.name, url: item.url, click_total: item.click_total, impressions_total: item.impressions_total, ctr: item.ctr, position: item.position, start_date: item.start_date } }
        table_data_query << data.topquery.select("site_id, name, `key`, click_total, impressions_total, ctr, position, start_date").map { |item| { site_id: item.site_id, name: item.name, key: item.key, click_total: item.click_total, impressions_total: item.impressions_total, ctr: item.ctr, position: item.position, start_date: item.start_date } }
        data
      end.to_json

      tab_d_p = []
      tab_d_q = []

      table_data_query.each { |item| tab_d_q += item unless item.empty? }
      table_data_page.each { |item| tab_d_p += item unless item.empty? }

      post_rows(table_data, dataset_id, "data")
      post_rows(tab_d_q.to_json, dataset_id, "data_top_query")
      post_rows(tab_d_p.to_json, dataset_id, "data_top_page")
      offset += limit
    end

  end

  def data_db
    @files_json.each { |item| data_db_thread item }
  end

  def read_file_json mask
    @base_path = Dir.pwd if @base_path.nil?
    @json = @base_path + "/unexpected_tasks/hamster_m24task/json/"
    Dir.chdir @json
    @files_json = Dir.glob "*"+mask

    @files_json.map! { |file| { file_name: file, table: file.split("_"+mask)[0], content: File.read(file) } }
    Dir.chdir @base_path
    dataset_access
    @files_json.each { |item| create_tables(item) if item[:id].nil? }
  end

  def run
    # report "Start export in Popwer Bi"
    read_file_json "powerbi.json"
    auth

    data_db
  end

end
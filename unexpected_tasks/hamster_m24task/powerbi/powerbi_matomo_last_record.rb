require_relative 'powerbi_matomo'

class PowerBiLastRecord < PowerBiReportsMatomo

  #TODO START: Private methods
  private
  def log_error(message)
    @logger.error(message)
  end

  def log_fatal(message)
    @logger.fatal(message)
  end

  def log_warning(message)
    @logger.warn(message)
  end
  #FILTER('InternetSales_USD', RELATED('SalesTerritory'[SalesTerritoryCountry])<>"United States")
  #      ,'InternetSales_USD'[SalesAmount_USD])

  def matomo_id_values(dataset_id, start_at = 1)
    queries = { queries: [{ query: "EVALUATE FILTER(lva, lva[idlink_va] >= #{start_at} && lva[idlink_va] < #{100000+start_at}) ORDER BY lva[idlink_va]"  }] }
    result = query_execute(dataset_id, queries)
    result["results"].first["tables"].first["rows"].map  { |value| value["lva[idlink_va]"] } unless result.nil?
  end

  def matomo_lva_id_count(dataset_id)
    queries = { queries: [{ query: "EVALUATE { COUNTROWS ( lva ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end

  def matomo_lva_id_min(dataset_id)
    queries = { queries: [{ query: "EVALUATE { MIN ( lva[idlink_va] ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end

  def matomo_lva_id_max(dataset_id)
    # dataset_id = @dataset["id"]
    queries = { queries: [{ query: "EVALUATE { MAX ( lva[idlink_va] ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end
  # получить начальный ID
  def insert_value_in_powerbi(ids, config)
    limit = 9000
    offset = 0
    dataset_id = config[:id]
    tables = JSON.parse(config[:content])

    select_column = tables["tables"][2]["columns"].map {|item|  "`#{item["name"]}`" }.join(",")

    # res = MatomoLogLinkVisitAction.count
    # res_max = MatomoLogLinkVisitAction.minimum("idlink_va")
    # res_min = MatomoLogLinkVisitAction.maximum("idlink_va")

    # last_matomo_lva_id = matomo_lva_id(dataset_id)

    while (res = MatomoLogLinkVisitAction.select(select_column).where("idlink_va IN (?)", ids ).limit(limit).offset(offset)).size > 0
      begin
        table_data = ""
        table_data = res.to_json
        ret = post_rows(table_data, dataset_id, "lva")
        offset += limit
      rescue => err
        @logger.fatal(err)
        @logger.fatal(ret)
        @logger.fatal(table_data)
      end
    end
  end

  def find_id_not_record(dataset_id, config)
    start_at = 1

    while !(res = matomo_id_values(dataset_id, start_at)).empty?

        limit = 1000
        offset = 0
        res_query = []
      begin
        not_in = res.join(",")
        query = "SELECT * FROM ( SELECT idlink_va FROM matomo_log_link_visit_action ORDER BY idlink_va LIMIT #{res.size} OFFSET #{ start_at - 1 } ) AS va_log
        WHERE idlink_va NOT IN(#{not_in})"

        res_query = MatomoLogLinkVisitAction.connection.execute(query).map { |item| item.first }
        insert_value_in_powerbi(res_query, config) if !res_query.empty?
      rescue => err
        err.inspect
      end

      start_at = res.last + 1 if res_query.empty?
    end

  end

  def begin_id

  end

  def end_id

  end
  # получить конечный ID

  #TODO END: Private methods
  
  #Public functions
  public
  def initialize(config)
    super(config)
    puts "Init variables Matomo"
    read_file_json "matomo.json"
    auth

    data_db

    res = MatomoLogLinkVisitAction.log_values
    pp res
    puts finish
  end



  def data_db_thread(config)
    data_set = config[:id]
    find_id_not_record(data_set, config)
  end

end

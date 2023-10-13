require 'logger'
require_relative '../model/matomo_log_action'
require_relative '../model/matomo_site'
require_relative '../model/matomo_log_view'
require_relative '../model/matomo_log_link_visit_action'
require_relative '../model/matomo_log'
require_relative '../model/matomo_log_visit'
require_relative './powerbi'

class PowerBiReportsMatomo < PowerBiReports



  def initialize(config)
    super(config)
    @logger = Logger.new("log/m24.log")
    @logger.level = Logger::DEBUG
  end

  def matomo_site_id(dataset_id)
    # dataset_id = @dataset["id"]
    queries = { queries: [{ query: "EVALUATE { MAX ( sites[idsite] ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end

  def matomo_visit_id(dataset_id)
    # dataset_id = @dataset["id"]
    queries = { queries: [{ query: "EVALUATE { MAX ( lv[idvisit] ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end

  def matomo_lva_id(dataset_id)
    # dataset_id = @dataset["id"]
    queries = { queries: [{ query: "EVALUATE { MAX ( lva[idlink_va] ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end

  def matomo_action_id(dataset_id)
    # dataset_id = @dataset["id"]
    queries = { queries: [{ query: "EVALUATE { MAX ( la[idaction] ) }" }] }
    result = query_execute(dataset_id, queries)
    unless (result["results"].first["tables"].first["rows"].first["[Value]"].nil?)
      return result["results"].first["tables"].first["rows"].first["[Value]"]
    else
      return 0
    end
  end



  def data_db_thread config
    offset = 0
    limit = 500
    retries = 5

    tables = JSON.parse(config[:content])

    begin
      dataset_id = config[:id]
      last_matomo_site_id = matomo_site_id(dataset_id)

      while (res = MatomoSite.select("idsite, name, main_url, ts_created, ecommerce,sitesearch,
sitesearch_keyword_parameters, sitesearch_category_parameters, timezone,currency,exclude_unknown_urls,
excluded_ips, excluded_parameters, excluded_user_agents, `group`,`type`, keep_url_fragment, creator_login").where("idsite > ?", last_matomo_site_id).limit(limit).offset(offset)).size > 0

        begin
          table_data = ""
          table_data = res.to_json
          ret = post_rows(table_data, dataset_id, "sites")
          offset += limit
        rescue => err
          @logger.fatal(err)
          @logger.fatal(ret)
          @logger.fatal(table_data)
        end
      end
      #надо добавить проверку на последний индекс чтоб понимать там нужно что то добавлять или нет

      select_column = tables["tables"][2]["columns"].map {|item|  "`#{item["name"]}`" }.join(",")

      res = MatomoLogLinkVisitAction.count
      res_max = MatomoLogLinkVisitAction.minimum("idlink_va")
      res_min = MatomoLogLinkVisitAction.maximum("idlink_va")



      last_matomo_lva_id = matomo_lva_id(dataset_id)
      while (res = MatomoLogLinkVisitAction.select(select_column).where("idlink_va > ?", last_matomo_lva_id ).limit(limit).offset(offset)).size > 0
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

      select_column = tables["tables"][1]["columns"].map {|item| "`#{item["name"]}`" }.join(",")

      last_visit_id = matomo_visit_id(dataset_id)

      while ( (res = MatomoLogVisit.select(select_column).where("idvisit > ?", last_visit_id ).limit(limit).offset(offset)).size > 0 )
        begin
          table_data = ""
          table_data = res.to_json
          ret = post_rows(table_data, dataset_id, "lv")
          offset += limit
        rescue => err
          @logger.fatal(err)
          @logger.fatal(ret)
          @logger.fatal(table_data)
        end
      end

      select_column = tables["tables"][3]["columns"].map {|item| "`#{item["name"]}`" }.join(",")
      last_matomo_action_id = matomo_action_id(dataset_id)
      while ((res = MatomoLogAction.select(select_column).where("idaction > ?", last_matomo_action_id ).limit(limit).offset(offset)).size > 0 )
        begin
          table_data = ""
          table_data = res.to_json
          ret = post_rows(table_data, dataset_id, "la")
          offset += limit
        rescue => err
          @logger.fatal(err)
          @logger.fatal(ret)
          @logger.fatal(table_data)
        end
      end

    rescue StandardError => err
      pp err
    end

  end

  def run
    puts "motomo"
    read_file_json "matomo.json"
    auth
    data_db
  end

end
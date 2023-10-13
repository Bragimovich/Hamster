require_relative 'powerbi_matomo_last_record'
require_relative 'lib/matomo_stat'
require 'erb'



class PowerBiStatistics < PowerBiReportsMatomo

  #TODO START: Private methods
  private

  def get_template
    dir_template =  Dir.pwd + "/unexpected_tasks/hamster_m24task/sql_template"
    filename = Dir.children(dir_template).first
    filename = dir_template + "/" + filename
    temp_res = ERB.new(File.read(filename))
    temp_res.result(binding)
  end

  def get_all_existing
    sql = "SELECT DATE(server_time) AS start_date FROM matomo_log_link_visit_action GROUP BY start_date"
    res_sql = MatomoLogLinkVisitAction.connection.execute(sql)
    res_sql.to_a.map { |item|  item.first.to_s }
  end

  def data_exists (dataset_id)
    queries = { queries: [{ query: "EVALUATE VALUES(stat[stat_date])"  }] }
    result = query_execute(dataset_id, queries)
    result["results"].first["tables"].first["rows"].map  { |value| Date.parse(value.first[1]).to_date.to_s } unless result.nil?
  end



  # получить начальный ID

  # получить конечный ID

  #TODO END: Private methods

  #Public functions
  public

  def initialize(config)
    super
    puts "Init variables Matomo"
    #Request to api PowerBI
    auth
    read_file_json "statistic.json"
    data_db
  end

  #Вынести за пределы
  def matomo_id_values(dataset_id)
    queries = { queries: [{ query: "EVALUATE FILTER(lva, lva[idlink_va] >= #{start_at} && lva[idlink_va] < #{100000+start_at}) ORDER BY lva[idlink_va]"  }] }
    result = query_execute(dataset_id, queries)
    result["results"].first["tables"].first["rows"].map  { |value| value["lva[idlink_va]"] } unless result.nil?
  end

  def data_exists?(item_date)

  end

  def data_db_thread(config)
    data_set = config[:id]
    data_from_powerbi = data_exists(config[:id])
    @stat_date = Date.today
    existing_days = get_all_existing

    diff_array = existing_days.difference(data_from_powerbi)

    diff_array.each do |item_date|
        @stat_date = item_date
        template = get_template
        sql_result = MatomoLogLinkVisitAction.connection.execute(template, :as => :hash)
        res = sql_result.to_a(:as=>:hash)
        post_rows(res.to_json, data_set, "stat")
        puts "Done #{@stat_date}"
    end
    # find_id_not_record(data_set, config)
  end

  def run

  end
end

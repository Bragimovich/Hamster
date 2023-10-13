require_relative './powerbi'

class PowerBiUpdate < PowerBiReports
  attr_writer :update_at
  def initialize(conf)
    super(conf)
  end

  def data_db_thread item_files
    offset = 0
    limit = 500

    start_id = id_last(item_files)
    start_id = 0 if start_id.nil?

    dataset_id = item_files[:id]
    media = (item_files[:table] === "analitycs" )? "analitics1" : item_files[:table]
    # start_date = Date.today() << 2

    while (res = GoogleConsoleData.select("id, name, url, discovered_url, click_total, impressions_total, ctr, position, start_date").where(name: media).where("DATE(updated_at) =  DATE(?)", @update_at).limit(limit).offset(offset)).size > 0
      table_data = res.to_json
      post_rows(table_data, dataset_id, "data")
      offset += limit
    end
  end

  def run
      # report "Start export in Popwer Bi"
      read_file_json "powerbi.json"
      auth
      data_db
  end

end
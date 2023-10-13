# frozen_string_literal: true
class Parser < Hamster::Parser

  def parse(page, run_id, file_name)
    processed_md5 = []
    doc = File.read(page)
    table = CSV.parse(doc, headers: true, quote_char: nil, col_sep: "\t")
    hash_array = []
    table.each do |data|
      data_hash = {}
      data.headers.each do |header|
        data_hash["#{header}"] = data[header]
        data_hash["#{header}"] = data_hash["#{header}"].strip unless data[header].nil?
      end
      data_hash["md5_hash"] = hash_generator(data_hash)
      processed_md5 << data_hash["md5_hash"]
      if file_name.include?"demographic"
        data_hash["year"] = Date.today.year.to_s 
        data_hash["aliases"] = data["aliases"] rescue nil
      end
      data_hash["run_id"] = run_id
      data_hash["touched_run_id"] = run_id
      data_hash["pl_gather_task_id"] = 175867003 
      data_hash["scrape_frequency"] = "Weekly"
      data_hash["last_scrape_date"] = "#{Date.today}"
      data_hash["next_scrape_date"] = "#{Date.today.next_month}"
      data_hash["expected_scrape_frequency"] = "Weekly" 
      data_hash["dataset_name_prefix"] = "nevada_criminal_offenders"
      data_hash["data_source_url"] = "https://ofdsearch.doc.nv.gov/form.php"
      data_hash["scrape_status"] = "Live"
      data_hash["scrape_dev_name"] = "Adeel"
      hash_array << data_hash.except("md5_hash")
    end
    [hash_array, processed_md5]
  end

  private

  def hash_generator(data_hash)
    columns_str = ""
    data_hash.keys.each do |key|
      columns_str = columns_str + data_hash[key].to_s
    end
    Digest::MD5.hexdigest columns_str
  end
end

# frozen_string_literal: true

class Parser <  Hamster::Parser

  def fetch_folder_info(html, folder)
    data        = Nokogiri::HTML(html.force_encoding("utf-8"))
    folder_info = data.css("table.DocumentBrowserDisplayTable tbody tr").select{|l| l.css("a")[0]['aria-label'] == folder}
    eventtarget = folder_info[0].css("button")[0]["onclick"].split("'")[1].gsub("$", ":")
    viewstate, eventvalidation, viewstategenerator, previouspage = form_info(data)
    [eventtarget, eventvalidation, viewstate, viewstategenerator, previouspage]
  end

  def fetch_all_folders(html)
    data = Nokogiri::HTML(html.force_encoding("utf-8"))
    folders_info_array = []
    data.css("table.DocumentBrowserDisplayTable tbody tr").each do |row|
      link = row.css("button")[0]["onclick"].split("'")[1].gsub("$", ":")
      name = row.css("td")[0].text.split("[")[0]
      hash = {:name => name, :link => link}
      folders_info_array << hash
    end
    viewstate, eventvalidation, viewstategenerator, previouspage = form_info(data)
    [[folders_info_array],[eventvalidation, viewstate, viewstategenerator, previouspage]]
  end

  def fetch_pdf_links(html)
    data = Nokogiri::HTML(html.force_encoding("utf-8"))
    data.css("table.DocumentBrowserDisplayTable tbody tr").map{|l| l.css("a")[0]['href'].split("/")[2]}
  end

  def parse(html, sub_folder, run_id)
    data_array = []
    data       = Nokogiri::HTML(html.force_encoding("utf-8"))
    data.css("table.DocumentBrowserDisplayTable tbody tr").each do |row|
      data_hash = {}
      data_hash[:document_name]     = row.css("td")[0].text.split("[")[0]
      data_hash[:page_count]        = row.css("td")[1].text
      data_hash[:src_date_created]  = Date.strptime(row.css("td")[3].text.split(" ")[0],'%m/%d/%Y') rescue nil
      data_hash[:src_date_modified] = Date.strptime(row.css("td")[4].text.split(" ")[0],'%m/%d/%Y') rescue nil
      data_hash[:src_pdf_link]      = "https://records.hawaiicounty.gov/weblink/#{row.css("a")[0]['href']}"
      data_hash[:folder_name]       = sub_folder.gsub("_", "-")
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:run_id]            = run_id
      data_hash[:data_source_url]   = "https://records.hawaiicounty.gov/weblink/browse.aspx?dbid=1"
      data_array << data_hash
    end
    data_array
  end

  private

  def form_info(data)
    eventvalidation    = data.css("#__EVENTVALIDATION")[0]['value']
    viewstate          = data.css("#__VIEWSTATE")[0]['value']
    viewstategenerator = data.css("#__VIEWSTATEGENERATOR")[0]['value']
    previouspage       = data.css("#__PREVIOUSPAGE")[0]['value']
    [viewstate, eventvalidation, viewstategenerator, previouspage]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end

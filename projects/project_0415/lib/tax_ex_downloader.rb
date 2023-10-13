# frozen_string_literal: true

@@path_zip_file ||= "projects/project_0415/data_download/pub78.csv"
@@url_zip ||= "https://apps.irs.gov/pub/epostcard/data-download-pub78.zip"

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[ein organization city state country classification last_date]
  columns.each do |key|
    if news_hash[key].nil?
      all_values_str = all_values_str + news_hash[key.to_s].to_s
    else
      all_values_str = all_values_str + news_hash[key].to_s
    end
  end
  Digest::MD5.hexdigest all_values_str
end


def remove_zip
  File.delete(@@path_zip_file) if File.exists?(@@path_zip_file)
  puts "delete file #{@@path_zip_file}"
end

def download
  content = open(@@url_zip)
  Zip::File.open_buffer(content) do |zip|
    zip.each do |entry|
      puts entry.name
      entry.extract(@@path_zip_file)
      # Do whatever you want with the content files.
    end
  end
  puts "end download"
end

def load_to_db(date, update, run_id)
  csv = CSV.parse(File.read(@@path_zip_file), {
    :col_sep => "|",
    :headers => false
  }
  )
  csv = csv[2..]
  csv.each do |row|
    existing_ein_array, existing_md5_hash = [], []
    existing_ein_array = get_existing_ein(row[0]) if update == 0
    next if row[0].in? existing_ein_array and update == 0

    us_tax_exempt = TaxExempt.new
    us_tax_exempt.ein = row[0]
    us_tax_exempt.organization = row[1]
    us_tax_exempt.city = row[2]
    us_tax_exempt.state = row[3]
    us_tax_exempt.country = row[4]
    us_tax_exempt.classification = row[5]
    us_tax_exempt.last_date = date

    data_for_md5 = {
      "ein": row[0],
      "organization": row[1],
      "city": row[2],
      "state": row[3],
      "country": row[4],
      "classification": row[5],
      "last_date": date
    }
    us_tax_exempt.md5_hash = make_md5(data_for_md5)

    existing_md5_hash = get_md5_hash(row[0]) if update == 1
    next if us_tax_exempt.md5_hash.in? existing_md5_hash and update == 1

    us_tax_exempt.run_id = run_id
    us_tax_exempt.touched_run_id = run_id

    us_tax_exempt.save
  end
end

def update_data(date, update, run_id)
  remove_zip
  download
  load_to_db(date, update, run_id)
  remove_zip
end
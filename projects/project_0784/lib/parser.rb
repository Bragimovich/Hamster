# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize
    super
    @keeper = Keeper.new
  end

  def get_csv_link(response)
    page = Nokogiri::HTML(response.body.force_encoding('utf-8'))
    "https://www.admin.sc.gov#{page.css('section.inner-body-content-hld a').first['href']}"
  end

  def parse_data(file)
    data_array = []
    md5_array = []
    CSV.foreach(file, encoding: 'ISO-8859-1', liberal_parsing: true) do |row|
      data_hash = {}
      data_hash[:name]               = "#{row.second} #{row.first}".to_s.squish
      data_hash[:agency]             = row[2].to_s.squish
      data_hash[:job_title]          = row[3].to_s.squish
      data_hash[:total_compensation] = row[4].to_s.squish
      data_hash[:bonuses]            = row[5].to_s.squish
      data_hash[:md5_hash]           = create_md5_hash(data_hash)
      data_hash[:run_id]             = keeper.run_id
      data_hash[:touched_run_id]     = keeper.run_id
      data_hash[:data_source_url]    = 'https://www.admin.sc.gov/transparency/state-salaries-lookup?agency=0&job=0&firstname=&lastname=&op=Submit+Query&form_build_id=form-dgvo_1RPspj6OnrPSfPP9OLyx0dk1QvjGmHVfX3tJ5c&form_id=salary_lookup_form'
      data_hash                      = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
      if (data_array.count == 5000)
        data_array = data_array.reject{ |e| e.empty? }
        md5_array = md5_array.reject{ |e| e.empty? }
        keeper.insert_records(data_array)
        keeper.update_touched_run_id(md5_array)
        data_array = []
        md5_array = []
      end
    end
    data_array = data_array.reject{ |e| e.empty? }
    md5_array = md5_array.reject{ |e| e.empty? }
    keeper.insert_records(data_array)
    keeper.update_touched_run_id(md5_array)
  end

  private

  attr_reader :keeper

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

end

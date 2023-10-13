# frozen_string_literal: true

class Parser < Hamster::Parser
  attr_reader :content
  
  def read_csv(file, lines_to_skip=1)
    lines = File.open(file, "r").readlines
    lines = lines[lines_to_skip..-1]
    @content = []
    lines.each do |line|
      line = line.encode("UTF-8", invalid: :replace, replace: "")
      row = CSV.parse(line.squish.gsub("=",""), quote_char: '"').flatten
      @content << row
    end
  end

  def process_data(&block)
    content.each do |arr|
      next if arr.first =~ / -, - -/

      data_hash = {
        name:                arr[0],
        date_admited:        format_date(arr[7]),
        registration_status: arr[6],
        phone:               arr[4],
        law_firm_city:       arr[2],
        law_firm_state:      arr[3],
        data_source_url:     "https://www.iacourtcommissions.org/"
      }

      data_hash = mark_empty_as_nil add_md5(data_hash)
      block.call(data_hash)
    end
  end
  
  private

  def format_date(value)
    date = value.split("/")
    month = date.shift
    day = date.shift
    Date.parse("#{date[0]}-#{month}-#{day}").strftime("%Y-%m-%d")
  rescue
    nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end

  def add_md5(data_hash)
    data_hash[:md5_hash] = Digest::MD5.hexdigest data_hash.values * ""
    data_hash
  end
end

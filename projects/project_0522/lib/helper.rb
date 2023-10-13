module Helper
  def self.included(base)
    base.extend(Helper)
  end

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
end

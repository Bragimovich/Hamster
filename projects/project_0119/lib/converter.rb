class Converter
  def initialize(run_id = 0, scraper_name = 'vyacheslav pospelov')
    @scraper_name = scraper_name
    @run_id = run_id
  end
  def string_to_link(string, url_prefix = "")
    string = clean_string(string)
    condition = string && string[0..3].include?("http")
    #absolute_uri = URI.join( base_url, string ).to_s
    condition ? string : "#{url_prefix}#{string}"
  end

  def string_to_time(string)
    string = clean_string(string)

    return if string.blank?

    Time.parse(clean_string(string)).strftime("%H:%M:%S")
  end

  def string_to_date(string, time = nil, is_datetime = nil)
    date = clean_string(string)

    return if date.blank?

    date = date.split(" ").join("-") if date.match?(/\d+ \d+ \d+/)
    arr = date.split('/')
    date = [arr[2], arr[0], arr[1]].join("-").to_s if arr.size == 3
    date = Time.parse(date).strftime('%Y-%m-%d').to_s
    date += " 00:00:00" if is_datetime && time.nil?
    time ? "#{date} #{time}" : "#{date}"
  end

  def article_to_teaser(article)
    teaser = find_teaser(article.css("*"))
    teaser = find_teaser(article.children) if teaser.blank?
    data_array = article.css("*").to_html.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
    sentence = find_teaser(data_array, true) unless data_array.blank?
    teaser = sentence if sentence&.include?('.')

    return if teaser.blank?

    validate_teaser(teaser)
  end

  def find_teaser(article, dot = nil)
    teaser = nil
    article.each do |node|
      node = clean_string(Nokogiri::HTML(node[0]).text)
      node = nil if dot && !(node&.include?('.'))
      next unless node

      return node if node.length > 35
    end
    teaser
  end

  def validate_teaser(teaser)
    teaser = clean_teaser(teaser)

    return if teaser.blank?

    teaser = teaser[0..597]
    if teaser[-1] == ":"
      "#{teaser.chop[0..597]}..."
    elsif teaser.include?(".")
      teaser[0..teaser.rindex(".")]
    else
      "#{teaser[0..597]}..."
    end
  end

  def clean_teaser(teaser)
    teaser = clean_string(teaser)

    return if teaser.blank?

    if teaser[0..10].include?('(')
      teaser = teaser.split(')', 2).last.strip
    end
    wrong_values = ["###", "Vaccines Near You", "See attached PDF"]
    wrong_values.each {|str| return nil if teaser.include?(str)}
    values_to_split = %w[– – -- ‒ - Washington WASHINGTON]
    values_to_split.each do|str|
      teaser = teaser.split(str, 2).last.strip if teaser[0..50].include? str
    end
    teaser
  end

  def clean_string(string)
    string = string.to_s
                   .gsub("&amp;", ' & ')
                   .gsub(/[^[:print:]]/, ' ')
                   .gsub('​', ' ')
                   .gsub(' ', ' ')
                   .gsub(' ', ' ')
                   .squish

    return if string.blank?

    unmodified_str = string
    string = string.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
    string = string.each_char.select { |c| c.bytes.first < 240 }.join('').to_s
    if unmodified_str != string
      Hamster.report(
        to: @scraper_name,
        message: "project-#{Hamster::project_number}: replaced string \n old = #{unmodified_str} \n new = #{string}",
        use: :both
      )
    end
    string
  end

  def clean_data(hash)
    return if hash.blank?

    @wrong = %w[--none-- -none- -- - none null nil]
    hash.transform_values do |value|
      value = value.to_s.strip
      value.empty? ? nil : (@wrong.include?(value.downcase) ? nil : value)
    end
  end

  def to_md5(var)
    md5 = ''
    md5 = Digest::MD5.hexdigest var if var.is_a?(String)
    md5 = Digest::MD5.hexdigest var.join if var.is_a?(Array)
    md5 = Digest::MD5.hexdigest var.values.join if var.is_a?(Hash)
    md5
  end
end
class Converter
  def initialize
    super
  end

  def string_to_link(string, url_prefix = "")
    string = clean_string(string)
    condition = string && string.include?("http")
    condition ? string : "#{url_prefix}#{string}"
  end

  def string_to_time(string)
    string = clean_string(string)

    return if string.blank?

    Time.parse(clean_string(string)).strftime("%H:%M:%S")
  end

  def string_to_date(string, time = nil)
    date = clean_string(string)

    return if date.blank?

    date = date.split(" ").join("-") if date.match?(/\d+ \d+ \d+/)
    arr = date.split('/')
    date = [arr[2], arr[0], arr[1]].join("-").to_s if arr.size == 3
    date = Time.parse(date).strftime('%Y-%m-%d').to_s
    time ? "#{date} #{time}" : "#{date}"
  end

  def article_to_teaser(article)
    teaser = nil
    article.css("*").each do |node|
      node = node.text.to_s.squish
      teaser =  node if node.length > 10
      break if teaser
    end
    unless teaser
      article.children.each do |node|
        node = node.text.to_s.squish
        teaser =  node if node.length > 10
        break if teaser
      end
    end
    #data_array = article.css("*").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)

    return if teaser.blank?

    validate_teaser(teaser)
  end

  def string_to_fio(name)
    # (?<= )(\w+)\.
    name = clean_string(name).gsub!(",", "")
    words = name.strip.split(" ")
    last_name = words[0]
    first_name = words[1] if words.length > 1
    middle_name = nil if words.length == 2
    middle_name = words[2] if words.length == 3
    middle_name = words[2] + words[3] if words.length == 4
    [
      first_name,
      middle_name,
      last_name
    ]
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

    if teaser[0..18].upcase.include?('WASHINGTON') && teaser[0..10].include?('(')
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
    string = string.to_s.gsub(/[^[:print:]]/, ' ').gsub('​', ' ').squish

    return if string.blank?

    string = string.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
    string.each_char.select { |c| c.bytes.first < 240 }.join('').to_s
  end
end
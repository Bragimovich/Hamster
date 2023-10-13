require 'week_of_month'

class Scrape < Hamster::Scraper
  URL_SITE = "https://www.midlandtexas.gov/982/Midland-County-DailyWeekly-COVID-19-Case"
  MONTH_NAME = I18n.t("date.month_names")
  WEEKDAY_NAME = I18n.t("date.abbr_day_names")

  private

  def download
    response = connect_to(URL_SITE)
    if response.status == 200
      site_body = Nokogiri::HTML(response.body)
      url = site_body.css("iframe").first.attr("src")
      Dasher.new(url, using: :hammer, headless: true).smash do |browser|
        sleep 2
        response = browser.at_css("iframe")
        @url_sheet = response.attribute("src")
      end

      Dasher.new(@url_sheet, using: :hammer, headless: true).smash do |browser|
        sleep 2
        @html_body = browser.body
      end
      table = Nokogiri::HTML(@html_body)
      @body = table.css("table tbody tr")
    else
      raise "Status site #{URL_SITE} return: #{response.status}"
    end
  end

  #Определяем индексы в таблице каждого месяца
  def index_tr_month arr
    index_tr = []
    arr.each_with_index {|item, index|  index_tr << { index: index, month_year: item.css("td").text } if item.text.match? /October|November|December|January|February|March|April|May|June|July|August|September/ }

    index_tr.each_with_index do |item, index|
      _beg = item[:index] + 2
      _end = (!!index_tr[index+1].nil?) ? arr.size - 1 : index_tr[index+1][:index] - 1

      index_tr[index][:index] = _beg
      index_tr[index].merge! ({index_end: _end})
    end

    index_tr
  end

  def transform_arr_date arr, data
    arr_tmp = []
    arr.each do |i|
      i.map! do |e|
        tmp_date = data + (e[:day].to_i-1)
        {
          date: tmp_date,
          day_names: Date::ABBR_DAYNAMES[tmp_date.wday],
          value: e[:value],
          day: e[:day],
          month: Date::MONTHNAMES[tmp_date.mon],
          year: tmp_date.year
        }
      end
      arr_tmp += i
    end
    arr_tmp
  end

  def data_month arr
    index_tr = index_tr_month arr

    arr_split = []
    index_tr.each do |item|
      tmp_arr = arr[item[:index]..item[:index_end]]
      arr_split << tmp_arr.map {|i| i.css("td")}
    end


    arr_split.map! do |item|

      twink_arr = []
      week_count = item.size / 2
      week_index = 0

      begin
          twink_arr << {
                        day: item[week_index*2],
                        data: item[(week_index*2)+1]
                       }
          week_index += 1
      end while (week_index < week_count)

      parse_data_week twink_arr
      #Разбить по паре предварительно посчитать сколько недель в месяце ( количество элементов делим на 2)
      # Каждую пару сопоставить и занести в базу
    end
    result = []

    index_tr.each_with_index do |item, index|
      result <<
        {
          month: Date::MONTHNAMES[Date.parse(item[:month_year]).month],
          year: Date.parse(item[:month_year]).year,
          data: transform_arr_date(arr_split[index], Date.parse(item[:month_year]))
        }
    end
    result
  end

  def join_arr arr_map
    a1 = arr_map[:day][3..-3]
    a2 = arr_map[:data][3..-3]

    ret_arr = []

    a1.each_with_index do |itm, inx|
      ret_arr << {day: itm[:v], value: a2[inx][:v]} unless itm[:v].empty?
    end

    ret_arr
  end

  def join_arr_m2 arr_map
    a1 = arr_map[:day][3..-3]
    a2 = arr_map[:data][3..-2]

    ret_arr = []

    a1.each_with_index do |itm, inx|
      ret_arr << {day: itm[:v], value: a2[inx][:v]} unless itm[:v].empty?
    end

    ret_arr
  end

  def parse_data_week twink_arr

    arr_map_tmp = []

    arr_map_tmp = twink_arr.map do |item|
      {day: item[:day].map {|i| {d: ( i.attr("colspan").to_i > 0 )?  i.attr("colspan").to_i : 1 ,v: i.text } } ,
       data: item[:data].map {|i| {d: ( i.attr("colspan").to_i > 0 )?  i.attr("colspan").to_i : 1 ,v: i.text } } }
    end

    arr_map_tmp.map! do |i|
      if i[:day].size == i[:data].size
        join_arr(i)
      else
        join_arr_m2(i)
      end
    end

    arr_map_tmp

  end

  def parse_html
    list_tr = @body
    arr_tr = []
    list_tr.each { |item| arr_tr.push(item) unless item.nil? }
    data_month arr_tr
  end

  public

  def initialize(options)
    super
    @error_count = 0
  end

  def run
    download rescue retry if (@error_count += 1) < 5
    parse_html
  end

end

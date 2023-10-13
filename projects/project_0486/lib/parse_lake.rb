# frozen_string_literal: true




class ParseLake < Hamster::Parser
  attr_writer :activities_callback
  BASE_URL = "https://apps03.lakecountyil.gov/inmatesearch/"
  def initialize
    super
  end
  def index_extract(index)

    booking_number = index.css(">td")[0].text
    url = BASE_URL + index.css(">td")[0].css("a").attr("href").value
    name = index.css(">td")[1].text
    sex = index.css(">td")[2].text
    booked = index.css(">td")[3].text

    booked = (booked.empty?)? "" : Date.strptime(booked, "%m/%d/%Y")

    location = index.css(">td")[4].text
    { booking_number: booking_number, url: url, name: name, sex: sex, booked: booked, location: location }
  end

  def content?(content)
    !content.text.match?("No Inmates Found")
  end

  def parse_index(content)
    @table_html = content.css("form > table").first
    @table_html = @table_html.css("tr > td > div > table").first
    delete_page_index
    delete_header
    @table_html.css(">tr").map { |index| index_extract(index) }
  end

  def delete_page_index
    if @table_html.css(">tr").last.css("td>table").size > 0
      @table_html.css(">tr").last.remove
    end
  end

  def delete_header
    @table_html.css(">tr").first.remove
  end

  def parse_content(content)
    @content = content
    @end_page = false
    info_src = @content.at("table[id=InmateDetailTable1]")
    @activities_src = @content.at("table[id=SearchResultsGrid]").clone
    info  = {
      photo: BASE_URL + photo(info_src),
      name: name(info_src),
      address: address(info_src),
      booking: booking(info_src),
      sex: sex(info_src),
      status: status(info_src),
      activities: activities
    }
  end

  def activities

    activities_result = []
    bond_amount = 0
    if !@activities_src.nil?
      begin
        @activities_src.css(">tr.SearchResultsBanner").remove
        @activities_src.at("> tr > td > table").parent.parent.remove if !@activities_src.css(">tr > td > table").empty?
        tmp_activity = @activities_src.css(">tr").map do |item|
          confined = item.css(">td")[0].text.squish
          court_date = item.css(">td")[1].text.squish
          tmp_bond_amount = item.css(">td")[4].text.squish
          if !tmp_bond_amount.empty?
            tmp_bond_amount = tmp_bond_amount.gsub('$', '').gsub(',', '').to_i
            bond_amount += tmp_bond_amount
          end
          {
            confined: (confined.empty?)? nil:Date.strptime(confined, "%m/%d/%Y"),
            court_date: (court_date.empty?)? nil: DateTime.strptime(court_date, "%m/%d/%Y %H:%M"),
            court_time: (court_date.empty?)? nil: DateTime.strptime(court_date, "%m/%d/%Y %H:%M"),
            disposition: item.css(">td")[2].text.squish,
            bond_amount: '',
            bond_category: '',
            bond_type: item.css(">td")[3].text.squish,
            offense: item.css(">td")[5].text.squish,
          }
        end

        if bond_amount > 0
          tmp_activity.first[:bond_amount] = bond_amount.to_s
          tmp_activity.first[:bond_category] = 'Total Bond'
        end
        activities_result << tmp_activity
      end while pages?
    end

    activities_result.flatten
  end

  def pages?
    return false if ( @content.css("table[id=SearchResultsGrid] > tr > td > table").empty? || @activities_callback.nil? || @end_page )
    func_parse = Proc.new{ |content| next_page_activities(content) }
    @content, @end_page = @activities_callback.call(@content, func_parse)
    @activities_src = @content.at("table[id=SearchResultsGrid]").clone
    true
  end

  def status(table)
    table.at(">tr #lblStatus").text.squish
  end

  def sex(table)
    table.at(">tr #lblSex").text.squish
  end
  def booking(table)
    table.at(">tr #lblBookingNumber").text.squish
  end

  def address(table)
    table.at(">tr #lblCityStateZip").text.squish
  end

  def name(table)
    table.at(">tr #lblName").text.squish
  end
  def photo(table)
    a = table.css("img[id=InmateThumbNail]")
    a.attr("src").value
  end

  def next_page_activities (content)
    query_post_hash = {}
    param = content.css("form > input[type=hidden]")
    param.each {|item| query_post_hash.merge!({"#{item.attr("name").squish}" => "#{item.attr("value").squish}" }) }
    query_post_hash["__EVENTTARGET"] = "SearchResultsGrid"

    action = content.at("form").attr("action")
    table_page = content.at("table[id=SearchResultsGrid] table")
    current_page = table_page.at("span").text.to_i
    total_page = table_page.css("tr>td").size
    next_page = current_page + 1
    query_post_hash["__EVENTARGUMENT"] = "Page$#{next_page}"
    [action, current_page, total_page, next_page, query_post_hash]
  end

  def index_next_page(content_html)
    param_query_post_hash = {}
    count_page = 1
    param = content_html.css("form > input[type=hidden]")
    param.each {|item| param_query_post_hash.merge!({"#{item.attr("name").squish}" => "#{item.attr("value").squish}" }) }
    table_page = content_html.css("table[id=SearchResultsGrid] table")
    count_page = content_html.css("table[id=SearchResultsGrid] table")[0].css("tr > td").size if table_page.size > 0
    [param_query_post_hash, count_page]
  end

end

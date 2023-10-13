
class Parser < Hamster::Parser

  def initialize
    super
  end

  def get_table_from_page(page)
    document = Nokogiri::HTML page
    table = document.css('table#opinion_contentTable tbody tr')
    return table
  end

  def parse_row_table(row, domain)

    hash_data = {}

    data = row.css('td').map {|cell|
      if !cell.css('br').empty?
        cell.css('label.blue_dg_label').children.map { |c| c.text}[0]
      else
        cell.text != ' ' ? cell.text : cell.css('a')
      end
    }

    party = data[3].split('VS').map {|el| el.strip}

    hash_data[:court_id]          = 432
    hash_data[:activity_date]     = Date.strptime(data[0].delete(' '), '%m/%d/%Y').strftime('%Y-%m-%d')
    hash_data[:activity_desc]     = nil
    hash_data[:activity_type]     = 'Opinion'
    hash_data[:case_id]           = data[1]
    hash_data[:case_name]         = data[3]
    hash_data[:is_lawyer]         = 0
    hash_data[:party_name]        = party
    hash_data[:source_link]       = hash_data[:file] = domain + data[2][0]['href']
    hash_data[:source_type]       = 'activity'
    hash_data[:file_name]         = data[2][0]['href'][24..]

    key = "us_courts_expansion/#{hash_data[:court_id]}/#{hash_data[:case_id]}/#{hash_data[:file_name]}"

    hash_data[:key]               = key.gsub('%', '-')

    return hash_data
  end

  def get_date(body)
    document = Nokogiri::HTML body
    first_row = document.at_css('table#opinion_contentTable tbody tr')
    data = first_row.css('td').map {|cell| cell.text != ' ' ? cell.text : cell.css('a')}
    Date.strptime(data[0].delete(' '), '%m/%d/%Y').strftime('%Y-%m-%d')
  end

  def get_arr_links(page)
    document = Nokogiri::HTML page
    document.css('tr.dg_tr td a').map {|link| link['href']}
  end

end


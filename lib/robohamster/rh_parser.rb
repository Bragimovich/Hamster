# frozen_string_literal: true

class RoboHamsterParser < Hamster::Parser

  def initialize(*_)
    super
  end


  # Get elements from index page
  def get_elements_from_index(html, config)
    doc = Nokogiri::HTML(html)
    root = doc.css(config[:root])
    new_elements = []
    root.css(config[:element]).each do |element|
      new_element = data_from_page(config[:columns], element)
      new_elements.push(new_element)
    end
    new_elements
  end

  def get_element_page(html, page_config)
    doc = Nokogiri::HTML(html)

    root = doc.css(page_config[:root])
    new_element = data_from_page(page_config[:columns], root)

    new_element
  end

  def next_page(html, nokogiri_next_page, url)
    doc = Nokogiri::HTML(html)
    if !nokogiri_next_page.match(/(^a)|( a)/)
      nokogiri_next_page += ' a'
    end
    link_html = doc.css(nokogiri_next_page)[0]
    if !link_html.nil?
      next_page = link_html['href']
    else
      return
    end
    if next_page[0]=='/'
      final_url = url.match(/^https?:\/\/[\w\W]*\//)[0] + next_page[1..]
    elsif next_page.match(/^http/)
      final_url = next_page
    elsif next_page[0]=='?'
      final_url = url.split('?')[0] + next_page
    else
      final_url = url.match(/^https?:\/\/[\w\W]*\//)[0] + next_page[1..]
    end
    final_url
  end

  private

  def data_from_page(columns_hash, body)
    new_element = {}
    # cut_begin_text, cut_end_text = "__CUT BEGIN__", "__CUT END__"
    columns_hash.each do |column_name, data|
      body_object = body
      column_data = body_object.css(data[:nokogiri])[0]

      # Choose what to take from the item
      if data[:gather] && !column_data.nil?
        column_data =
          case data[:gather]
          when 'inner html'
            column_data.to_s
          when 'inner content'
            column_data.content
          else
            column_data[data[:gather]]
          end
      elsif !column_data.nil?
        column_data = column_data.content
        column_data = nil if column_data.strip==''
      end

      # Cut string by cut_from and cut_to parameter
      if !column_data.nil?
        [:cut_from, :cut_to].each do |cut|
          if data[cut]
            data[cut].split("||").each do |cut_str|
              column_data = column_data.split(cut_str)[-1]   if cut==:cut_from
              column_data = column_data.split(cut_str)[0]    if cut==:cut_to
            end
          end
        end
      end

      # Working with date
      new_element[column_name] =
        if data[:data_type] == "date" && !column_data.nil?
          correcting_date(column_data.strip, data[:date_structure])
        elsif !column_data.nil?
          column_data.strip.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        else
          nil
        end
    end

    new_element
  end

  def correcting_date(date_str, date_structure=nil)
    if !date_structure.nil?
      DateTime.strptime(date_str, date_structure)
    elsif date_str.match(/\d{1,2}\/\d{1,2}\/\d{4}/)
      Date.strptime(date_str, '%m/%d/%Y')
    elsif date_str.match(/\d{4}-\d{1,2}\-\d{1,2}/)
      Date.strptime(date_str, '%Y-%m-%d')
    else
      DateTime.parse(date_str)
    end
  end
end

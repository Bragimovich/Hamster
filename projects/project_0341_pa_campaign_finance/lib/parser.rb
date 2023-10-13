# frozen_string_literal: true

class Parser < Hamster::Parser
  CURRENT_YEAR = Time.now.year.to_s

  def parse_csv_publication_date(html)
    doc = Nokogiri::HTML(html)
    table = doc.at_css('[id="onetidDoclibViewTbl0"]')
    table.search('tr').drop(1).each_with_index do |tr, _index_tr|
      if text_of_child_element(tr.search('td')[1]) == CURRENT_YEAR
        date_str = text_of_child_element(tr.search('td')[2]).split(' ').first
        return Date.strptime(date_str, '%m/%d/%Y')
      end
    end
  end

  def parse_csv_url(html)
    doc = Nokogiri::HTML(html)
    table = doc.at_css('[id="onetidDoclibViewTbl0"]')
    table.search('tr').drop(1).each_with_index do |tr, _index_tr|
      if text_of_child_element(tr.search('td')[1]) == CURRENT_YEAR
        return tr.search('td')[1].children.first['href']
      end
    end
  end

  def committees_file_name
    find_file_name('filer')
  end

  def contributions_file_name
    find_file_name('contrib')
  end

  def expenditures_file_name
    find_file_name('expense')
  end

  def find_file_name(file_pattern)
    files = Dir["#{storehouse}/store/*"]
    files.each do |file_path|
      file_name = file_path.split('/').last
      return file_name if file_name.include? file_pattern
    end
  end

  private

  def text_of_child_element(element)
    element.children.children.text
  end
end

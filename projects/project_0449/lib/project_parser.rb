require_relative '../lib/parser'

class ProjectParser < Parser

  def unique_columns(html_arr)
    find_unique_rows(html_arr, 'table td.brcolumn1-a')
  end

  def onclick_values
    elements_list(type: 'text', css: 'table tr.brrow td.brcolumn1 a', attribute: 'onclick')
  end

  def parse_attorneys
    names = elements_list(type: 'text', css: 'table tr.brrow td.brcolumn1 a')
    bar_numbers = onclick_values.map { |el|  el.delete("^0-9")}
    law_firm_cities = elements_list(type: 'text', css: 'table tr.brrow td.brcolumn2')
    law_firm_zips = elements_list(type: 'text', css: 'table tr.brrow td.brcolumn3')
    names.map.with_index do |full_name ,index|
      {
        bar_number: bar_numbers[index],
        full_name: full_name,
        law_firm_zip: law_firm_zips[index],
        law_firm_city: law_firm_cities[index]
      }
    end
  end

  def parse_attorney_info(hash)
    data_source_url = 'https://courts.ms.gov/bar/barroll/barroll.php#dispArea'
    names = [
      "SCT Admission Date:",
      "Phone:",
      "Email:",
      "Fax:",
      "State:",
      "City:",
      "Zip Code:",
      "Address:",
      "Firm:"
    ]
    arr = elements_list(type: 'text', css: 'td.brcolumn2-a', names_css: 'td.brcolumn1-a', names: names)
    puts "row_values = #{arr}"
    #law_firm_address = ""
    if arr[7].is_a? Array
      law_firm_address1 = arr[7][0]
      law_firm_address2 = arr[7][1]
      if arr[7][0].blank?
        law_firm_address = arr[7][1]
      elsif arr[7][1].blank?
        law_firm_address = arr[7][0]
      else
        law_firm_address = arr[7].join(', ')
      end
    else
      law_firm_address = arr[7]
      law_firm_address1 = arr[7]
    end
    #law_firm_address += hash[:law_firm_city] + ", " unless !hash.key?(:law_firm_city) || hash[:law_firm_city].blank?
    #law_firm_address += arr[4] + " " unless arr[4].blank?
    #law_firm_address += hash[:law_firm_zip] unless !hash.key?(:law_firm_zip) || hash[:law_firm_zip].blank?
    #law_firm_address = nil if law_firm_address.blank?

    data = {
      date_admited: @converter.string_to_date(arr[0]),
      phone: arr[1],
      email: arr[2],
      fax: arr[3],
      law_firm_state: arr[4],
      law_firm_city: arr[5],
      law_firm_zip: arr[6],
      law_firm_address: law_firm_address,
      law_firm_address1: law_firm_address1,
      law_firm_address2: law_firm_address2,
      law_firm_name: arr[8],
      data_source_url: data_source_url
    }
    data.merge!(hash)
  end
end

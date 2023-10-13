# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def parse_main_page
    {
      '__LASTFOCUS' => '',
      '__VIEWSTATE' => @html.css("input[id='__VIEWSTATE']").attr("value").text,
      '__VIEWSTATEGENERATOR' => @html.css("input[id='__VIEWSTATEGENERATOR']").attr("value").text,
      '__EVENTARGUMENT' => '',
      '__EVENTVALIDATION' => @html.css("input[id='__EVENTVALIDATION']").attr("value").text,
      'ctl00$ContentPlaceHolder1$txtJurisNo' => ''
    }
  end

  def check_count_page
    record = @html.css("span[id='ContentPlaceHolder1_lblCount']").children.text.to_f
    (record/200.0).ceil
  end

  def parse_list
    lawyers_list = []
    @has_records = @html.css("span[id='ContentPlaceHolder1_lblCount']").text.present?
    if @has_records
      @html.css("table[id='ContentPlaceHolder1_GVDspCivInq']").css("tr[style]").each_with_index do |tr, index|
        unless index == 0
          @tr = tr
          lawyers_list << lawyer_data
        end
      end
    else
      lawyers_list << lawyer_data
    end 
    lawyers_list.compact
  end

  def bar_number
    @has_records ? @tr.css('td')[0].text.strip : @html.css("span[id='ContentPlaceHolder1_lblJurisNo']").text
  end

  def type
    @has_records ? @tr.css('td')[1].text.strip : @html.css("span[id='ContentPlaceHolder1_lblJurisType']").text
  end

  def name
    if @has_records
      @raw_info = @tr.css('td')[2].css('tr').map {|el| el.text.strip}
      @raw_info.first
    else
      @html.css("input[name='ctl00$ContentPlaceHolder1$txtJurisLastName']").attr("value").text.strip
    end
  end

  def lawyer_data
    hash = {
      bar_number: bar_number,
      type: select_type(type),
      name: name,
      date_admited: date,
      registration_status: registration_status.strip,
      raw_address: raw_address
    }
    hash = nil if type == "F" && !name.include?("PHV")
    hash
  end

  def date
    if @has_records
      raw_date = @raw_info[1].split(':').last.gsub(")", "").split('/') rescue nil
      Date.parse((raw_date[2] + raw_date[0] + raw_date[1])).strftime("%Y-%m-%d") rescue nil
    else
      raw_date = @html.css("span[id='ContentPlaceHolder1_lblAdmDate']").text.split('/') rescue nil
      Date.parse((raw_date[2] + format("%02d",raw_date[0]) + format("%02d",raw_date[1]))).strftime("%Y-%m-%d") rescue nil
    end
  end
  
  def registration_status
    if @has_records
      @raw_info.last.split(':').last
    else
      @html.css("span[id='ContentPlaceHolder1_lblStatus']").text
    end
  end

  def raw_address
    raw_address =
      if @has_records
        @tr.css('td')[7].css('span').inner_html.split('<br><b>').first.strip
      else
        @html.css("span[id='ContentPlaceHolder1_lblOfficeAddress']").inner_html.strip
      end
    raw_address&.include?("Address Not Available") ? nil : raw_address
  end

  def select_type(type)
    types = {
      "A" => "Attorney, (Juris Type 'A')",
      "J" => "Judge, (Juris Type 'J')",
      "K" => "Senior Judge, (Juris Type 'K')",
      "R" => "Referee, (Juris Type 'R')",
      "Q" => "Family Support Magistrate, (Juris Type 'Q')",
      "M" => "Motor Vehicle/Small Claims Magistrate, (Juris Type 'M')",
      "T" => "Attorney Trial Referee, (Juris Type 'T')",
      "U" => "ADR Attorney Adjunct, (Juris Type 'U')",
      "O" => "Federal Judicial Officers, (Juris Type 'O')",
      "D" => "Public Defender, (Juris Type 'D')",
      "G" => "Attorney Generals, (Juris Type 'G')",
      "H" => "Tax Attorney, (Juris Type 'H')",
      "S" => "State’s Attorney, (Juris Type 'S')",
      "P" => "Commission on Child Protection-CCPA, (Juris Type 'P')",
      "V" => "Fact finder, (Juris Type 'V')",
      "X" => "Non-Attorney, (Juris Type 'X')",
      "Z" => "Private Alternative Dispute Resolution Providers, (Juris Type 'Z')",
      "F" => "Attorneys permitted to appear PHV, (Juris Type 'F')",
      "C" => "Authorized House Counsel, (Juris Type 'C')"
    }
    types[type]
  end
end

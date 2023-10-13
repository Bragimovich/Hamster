# frozen_string_literal: true
require_relative '../lib/manager'

class Parser < Hamster::Parser

  COURT_ID = 308

  def initialize
    super
    # code to initialize object
  end


  def get_access_token(response)
    html = Nokogiri::HTML response.body
    data_hash = {
      viewstate:  html.xpath("//input[@id='__VIEWSTATE']//@value").text,
      viewstategenerator: html.xpath("//input[@id='__VIEWSTATEGENERATOR']//@value").text
    }
    data_hash
  end

  def get_total_pages(response)
    html = Nokogiri::HTML response.body
    total_page = html.xpath("//ul[@class='pagination']//li")[-2].text.squish().to_i
    return total_page
  end

  def get_pdf_urls(file_content)
    html = Nokogiri::HTML file_content
    html.xpath("//div[@id='main_content']//table//tr")[1..-1].map{|e| "https://courts.delaware.gov" + e.xpath(".//td").first.xpath(".//a").first["href"]}
  end

  def parse_page(file_content, year)
    html = Nokogiri::HTML file_content
    table = html.xpath("//div[@id='main_content']//table//tr")[1..-1]
    return table
  end

  def parse_case_info(row, year, run_id)
    data_hash = {}
    data_hash = {
      court_id: COURT_ID,
      case_id: row.xpath(".//td")[2].xpath(".//a").text.strip(),
      case_name: row.xpath(".//td")[0].xpath(".//a").text.strip(),
      case_filed_date: nil,
      case_type: row.xpath(".//td")[4].text.strip(),
      case_description: nil,
      disposition_or_status: nil,
      status_as_of_date: nil,
      judge_name: row.xpath(".//td")[5].text.strip().gsub("\n"," ").strip(),
      lower_court_id: nil,
      lower_case_id: get_lower_case_id(row.xpath(".//td").first.xpath(".//a").first["href"], year, row.xpath(".//td")[2].xpath(".//a").text.strip()),
      data_source_url: "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"]
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_case_additional_info(row, year, run_id)
    data_hash = {}
    lower_court_name = get_lower_court_name(row.xpath(".//td").first.xpath(".//a").first["href"], year)
    lower_court_id = get_lower_case_id(row.xpath(".//td").first.xpath(".//a").first["href"], year, row.xpath(".//td")[2].xpath(".//a").text.strip())
    return {} if lower_court_name == "" and lower_court_id == ""
    data_hash = {
      court_id: COURT_ID,
      case_id: row.xpath(".//td")[2].xpath(".//a").text.strip(),
      lower_court_name: lower_court_name,
      lower_case_id: lower_court_id,
      lower_judge_name: nil,
      lower_judgement_date: nil,
      lower_link: nil,
      disposition:nil,
      data_source_url: "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"]
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_case_activities(row, year, run_id)
    data_hash = {}
    date = Date.strptime( row.xpath(".//td")[1].text.strip(), '%m/%d/%Y').to_s rescue nil
    data_hash = {
      court_id: COURT_ID,
      case_id: row.xpath(".//td")[2].xpath(".//a").text.strip(),
      activity_date: date,
      activity_desc: nil,
      activity_type: row.xpath(".//td")[6].text.squish,
      file: "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"],
      data_source_url: "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"]
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_case_party(row, year, run_id)
    parties = get_part_name(row.xpath(".//td").first.xpath(".//a").first["href"], year)
    array = []

    if !parties.empty? and !parties[:party1_name].nil?
      for i in 1..3 do
        data_hash = {}

        data_hash = {
          court_id: COURT_ID,
          case_id: row.xpath(".//td")[2].xpath(".//a").text.strip(),
          is_lawyer: 0,
          party_name: parties[:"party#{i}_name"],
          party_type: parties[:"party#{i}_type"],
          party_law_firm: nil,
          party_address: nil,
          party_city: nil,
          party_state: nil,
          party_zip: nil,
          party_description: parties[:raw_string],
          data_source_url: "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"]
        }

        data_hash = mark_empty_as_nil(data_hash)
        md5_hash = MD5Hash.new(columns: data_hash.keys)
        md5_hash.generate(data_hash)
        data_hash[:md5_hash] = md5_hash.hash
        data_hash[:run_id] = run_id
        data_hash[:touched_run_id] = run_id

        if parties[:party3_name].nil? and i == 3
          # DO NOTHING
        else
          array << data_hash
        end
      end
    elsif parties.empty?
      return []
    else
      data_hash = {
        court_id: COURT_ID,
        case_id: row.xpath(".//td")[2].xpath(".//a").text.strip(),
        is_lawyer: 0,
        party_name: nil,
        party_type: nil,
        party_law_firm: nil,
        party_address: nil,
        party_city: nil,
        party_state: nil,
        party_zip: nil,
        party_description: parties[:raw_string],
        data_source_url: "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"]
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      array << data_hash
    end

    return array
  end

  def parse_case_pdfs_on_aws(row, year, run_id)
    data_hash = {}
    link = "https://courts.delaware.gov" + row.xpath(".//td").first.xpath(".//a").first["href"]
    case_id = row.xpath(".//td")[2].xpath(".//a").text.strip()
    data_hash = {
      court_id: COURT_ID,
      case_id: case_id,
      source_type: "activity",
      aws_link: save_to_aws(link, year, case_id),
      source_link: link,
      aws_html_link: nil
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_relations_activity_pdf(run_id, activity_hash, aws_hash)
    data_hash = {}
    data_hash = {
      case_activities_md5:activity_hash,
      case_pdf_on_aws_md5: aws_hash
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  private

  def save_to_aws(link, year, case_id)
    file_name = link.split("id=").last.strip() + ".pdf"
    file_path = "#{storehouse}store/#{year}_pdfs/#{file_name}"
    body = File.read(file_path, mode: 'rb')
    aws_s3 = AwsS3.new(bucket_key = :us_court)
    id = case_id.gsub('&','').gsub(",", "").gsub('and','').gsub(';','').gsub('/','').gsub(':','').gsub(' ','').squish
    key = "us_courts_expansion/#{COURT_ID}/#{id}/#{file_name}"
    aws_link = aws_s3.put_file(body, key, metadata={ url: link })
    Hamster.logger.debug "  [+] FILE UPLOAD IN AWS!".green
    aws_link
  end

  def get_part_name(link, year)
    file_name = link.split("id=").last.strip() + ".pdf"
    file_path = "#{storehouse}store/#{year}_pdfs/#{file_name}"

    begin
      reader = PDF::Reader.new(file_path)
    rescue
      Hamster.logger.debug "INCORRECT FORMAT"
      return ""
    end

    text = reader.pages.first.text.scan(/^.+/)
    if text.select{|e| e.include? "§"}.empty?
      return []
    end
    begin
      result = ""
      text.each do |s|
        if s.include?("§")
          result += s.split("§")[0].strip + "\n" rescue ""
        end
      end

      if !result.include? "v."
        data_hash = {}
        data_hash = {
          party1_name: nil,
          party1_type: nil,
          party2_name: nil,
          party2_type: nil,
          party3_name: nil,
          party3_type: nil,
          raw_string: result.squish
        }
      elsif result.include? "v." and result.include? "\n\nand\n\n"
        p file_name
        array = result.split("v.")
        data = []

        array.each do |item|
          if item.include?("\n\nand\n\n")
            data.concat(item.split("\n\nand\n\n"))
          else
            data << item
          end
        end
        if data[1].split("\n\n").reject{|e| e == ""}.last.split("\n").count > 2 or data[1].split("\n\n").count() > 3
          party_2_type = data[1].split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.split("\n")[0..1].join(" ").squish
        else
          if data[1].split("\n\n").reject{|e| e == ""}.count > 2
            party_2_type = data[1].split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}[-2].squish
          else
            party_2_type = data[1].split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.squish
          end
        end

        if data.last.split("\n\n").reject{|e| e == ""}.last.split("\n").count > 2 or data.last.split("\n\n").count() > 3
          party_3_type = data.last.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.split("\n")[0..1].join(" ").squish
        else
          if data.last.split("\n\n").reject{|e| e == ""}.count > 2
            party_3_type = data.last.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}[-2].squish
          else
            party_3_type = data.last.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.squish
          end
        end

        data_hash = {}
        data_hash = {
          party1_name: data.first.split("\n\n").reject{|e| e == ""}.first.split(" as ").first.squish,
          party1_type: data.first.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.squish,
          party2_name: data[1].split("\n\n").reject{|e| e == ""}.first.split(" as ").first.squish,
          party2_type: party_2_type,
          party3_name: data.last.split("\n\n").reject{|e| e == ""}.first.split(" as ").first.squish,
          party3_type: party_3_type,
          raw_string: result.squish
        }
        p data_hash
      elsif result.include? "v."
        data = result.split("v.")
        if data.last.split("\n\n").reject{|e| e == ""}.last.split("\n").count > 2 or data.last.split("\n\n").count() > 3
          party_2_type = data.last.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.split("\n")[0..1].join(" ").squish
        else
          if data.last.split("\n\n").reject{|e| e == ""}.count > 2
            party_2_type = data.last.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}[-2].squish
          else
            party_2_type = data.last.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.squish
          end
        end

        data_hash = {}
        data_hash = {
          party1_name: data.first.split("\n\n").reject{|e| e == ""}.first.split(" as ").first.squish,
          party1_type: data.first.split("\n\n").reject{|e| e == ""}.reject{|e| e == "\n"}.last.squish,
          party2_name: data.last.split("\n\n").reject{|e| e == ""}.first.split(" as ").first.squish,
          party2_type: party_2_type,
          party3_name: nil,
          party3_type: nil,
          raw_string: result.squish
        }
      end

      return data_hash
    rescue => exception
      p exception
    end
  end

  def get_lower_judge_name(link, year)
    file_name = link.split("id=").last.strip() + ".pdf"
    file_path = "#{storehouse}store/#{year}_pdfs/#{file_name}"

    begin
      reader = PDF::Reader.new(file_path)
    rescue
      Hamster.logger.debug "INCORRECT FORMAT"
      return ""
    end
    page = reader.pages.first.text.scan(/^.+/)
    begin
      results = ''
      data = page.select{|e| e.include? "Before"}
      if !data.empty?
        results = data.first.split(",").first.gsub('Before','').strip()
      end

      return results
    rescue => exception
      p exception
    end
  end

  def get_lower_court_name(link, year)
    file_name = link.split("id=").last.strip() + ".pdf"
    file_path = "#{storehouse}store/#{year}_pdfs/#{file_name}"

    begin
      reader = PDF::Reader.new(file_path)
    rescue
      Hamster.logger.debug "INCORRECT FORMAT"
      return ""
    end
    array = reader.pages.first.text.scan(/^.+/)

    if array.select{|e| e.include? "§"}.empty?
      return ""
    end

    begin
      result = []
      array.each do |stre|
        if stre.include?("Court Below") or stre.include?("CourtBelow")
          if array[array.index(stre)].include? ":"
            data =  (array[array.index(stre)].split(':').count() != 1) ? array[array.index(stre)].split(':').last.strip : ""
            result << data
          elsif array[array.index(stre)].include? "—"
            data =  (array[array.index(stre)].split('—').count() != 1) ? array[array.index(stre)].split('—').last.strip : ""
            result << data
          elsif array[array.index(stre)].include? "–"
            data = (array[array.index(stre)].split('–').count() != 1) ? array[array.index(stre)].split('–').last.strip : ""
            result << data
          elsif array[array.index(stre)].include? "—"
            data = (array[array.index(stre)].split('—').count() != 1) ? array[array.index(stre)].split('—').last.strip : ""
            result << data
          elsif array[array.index(stre)].include? "-"
            data =  (array[array.index(stre)].split('-').count() != 1) ? array[array.index(stre)].split('-').last.strip : ""
            result << data
          elsif array[array.index(stre)].include? "−"
            data = array[array.index(stre)].split('−').count() != 1 ? array[array.index(stre)].split('−').last.strip : ""
            result << data
          end
          next_str = array[array.index(stre) + 1]
          if next_str.strip == "1"
            next_str = array[array.index(stre) + 2]
          end
          if !next_str.nil? && !next_str.empty?
            parts = next_str.split("§")
            result << parts.last unless parts.last.empty?
            break if array[array.index(stre) + 2].split("§").count == 1
          end
        elsif stre.include? "§" and stre.split("§").last.include?("Court")
          result << array[array.index(stre)].split().last.strip()
          next_str = array[array.index(stre) + 1]
          if next_str.strip == "1"
            next_str = array[array.index(stre) + 2]
          end
          if !next_str.nil? && !next_str.empty?
            parts = next_str.split("§")
            result << parts.last.strip() unless parts.last.empty?
            break if array[array.index(stre) + 2].split("§").count == 1
          end
        end
      end

      result = result.join(" ").gsub('Court Below','').squish

      return result
    rescue => exception
      p exception
      return ""
    end
  end

  def get_lower_case_id(link, year, case_id)
    file_name = link.split("id=").last.strip() + ".pdf"
    file_path = "#{storehouse}store/#{year}_pdfs/#{file_name}"

    begin
      reader = PDF::Reader.new(file_path)
    rescue => exception
      Hamster.logger.debug "INCORRECT FORMAT"
      return ""
    end

    page = reader.pages.first.text.scan(/^.+/)
    Hamster.logger.debug "INCORRECT FORMAT" "-----------EMPTY PDF------------" if page.empty?

    if page.select{|e| e.include? "§"}.empty?
      return ""
    end

    result = ""
    flag = false
    page.each_with_index do |s, i|

      if s.include?("§") or page[i+1].include?("§")
        flag = true
        if s.split("§").count() == 1
          result +=  "\n"
        else
          result += s.split("§")[1].strip + "\n" rescue ""
        end
      elsif flag == true
        break
      end
    end


    id = ""

    if result.include? "\n\n"
      if result.split("\n\n").count() != 1
        data = result.split("\n\n").reject{ |str| str == "" }.reject{|str| str == "\n"} rescue binding.pry
        data = (data.count() == 1 or data.empty?) ? "" : data.last
      else
        data = ""
      end

      if data.split("\n").count()  == 1
        if data.include? "No."
          id = data.split("No.").last.strip()
        elsif data.include? "Nos."
          id = data.split("Nos.").last.strip()
        elsif data.include? "No:"
          id = data.split("No:").last.strip()
        else
          id = ""
        end
        id = id.gsub(case_id, "").gsub("\n", ";").gsub("and",";").squish() rescue ""
      else
        final_id = []
        data_array = data.split("\n")
        data_array.each do |data|
          if data.include? "No."
            id = data.split("No.").last.strip()
          elsif data.include? "Nos."
            id = data.split("Nos.").last.strip()
          elsif data.include? "No:"
            id = data.split("No:").last.strip()
          else
            id = ""
          end
          final_id << id
        end
        id = final_id.reject{|e| e == ""}.join("; ").gsub(":", "").squish
      end

    else
      id = ""
    end
    if id[0] == ":"
      id = id.split(":", 2)[1..-1].join(" ").squish
    end

    return id
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

end


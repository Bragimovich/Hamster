class PdfParser < Hamster::Parser
  def initialize
    super
    @file_path = nil
  end

  def parse_pdf(file_path, reg_type)
    hash_data  = {}
    reader     = PDF::Reader.new(open(file_path))
    page       = reader.page(1)
    lines      = parse_page_data(page)
    @file_path = file_path
    case reg_type
    when 'State Candidate'
      state_candidate(lines)
    when 'Sponsoring Organization'
      sponsoring(lines)
    when 'Conduit'
      conduit(lines)
    else
      political_party(lines)
    end
  end

  def state_candidate(lines)
    hash_data = {}
    hash_data[:segregated_fund_name] = nil
    hash_data[:leader_of_legislative] = nil
    line_no   = 0
    loop do
      row = lines[line_no].map(&:text)

      break if row[0].match(/COMMITTEE TREASURER INFORMATION/)

      if row[0].match(/COMMITTEE INFORMATION/i)
        hash_data[:committee_id] = row.last.split.last
      elsif row[0].match(/Name of the Candidate/i)
        line_no += 1
        row = lines[line_no].map(&:text)
        full_name = row[0]
        if full_name
          hash_data[:candidate_full_name] = full_name
          hash_data[:candidate_first_name] = full_name.split(',')[0]
          if full_name.split(',')[1]
            hash_data[:candidate_last_name] = full_name.split(',')[1].strip.split(' ')[0]
            hash_data[:candidate_middle_name] = full_name.split(',')[1].strip.split(' ')[1]
          else
            hash_data[:candidate_last_name] = nil
            hash_data[:candidate_middle_name] = nil
          end
        else
          hash_data[:candidate_full_name] = nil
          hash_data[:candidate_first_name] = nil
          hash_data[:candidate_last_name] = nil
          hash_data[:candidate_middle_name] = nil
        end
        hash_data[:party_affillation] = row[1]
        hash_data[:office_branch] = row[2]
      elsif row[0].match(/Residence Address/i)
        line_no += 1
        row = lines[line_no].map(&:text)
        if row[0].match(/City, State and Zip:/i)
          line_no -= 1
          hash_data[:candidate_address] = nil
          hash_data[:candidate_phone] = nil
        else
          hash_data[:candidate_address] = row[0]
          hash_data[:candidate_phone] = row[1]
        end
      elsif row[0].match(/City, State and Zip:/i)
        line_no += 1
        row = lines[line_no].map(&:text)
        address = row[0]
        if address
          hash_data[:candidate_city] = address.split(',')[0]
          hash_data[:candidate_state] = address.split(',')[1].strip.split(' ')[0] rescue nil
          hash_data[:candidate_zip] = address.split(',')[1].strip.split(' ')[1] rescue nil
        else
          hash_data[:candidate_city] = nil
          hash_data[:candidate_state] = nil
          hash_data[:candidate_zip] = nil
        end
        hash_data[:election_date] = Date.strptime(row[1], '%m/%d/%Y') rescue nil
        hash_data[:candidate_email] = row[2]
      elsif row[0].match(/Committee Name:/i)
        line_no += 1
        row = lines[line_no].map(&:text)
        hash_data[:committee_name] = row[0]
        if row[1].match(/State Candidate/i)
          hash_data[:acronym] = nil
          hash_data[:committee_type] = row[1]
          hash_data[:committee_sub_type] = row[2]
        else
          hash_data[:acronym] = row[1]
          hash_data[:committee_type] = row[2]
          hash_data[:committee_sub_type] = row[3]
        end
      elsif row[0].match(/Committee Address/i)
        address = row[1].gsub("Committee Email:", "")
        address_data = address.split(",")
        if address_data.count == 4
          address_line = "#{address_data[0]}, #{address_data[1]}"
          city = address_data[2]&.strip
          state, zip = address_data[3]&.split(' ')
        else
          address_line = "#{address_data[0]}"
          city = address_data[1]&.strip
          state, zip = address_data[2]&.split(' ')
        end
        if address
          hash_data[:committee_address] = address_line
          hash_data[:committee_city] = city
          hash_data[:committee_state] = state
          hash_data[:committee_zip] = zip
        else
          hash_data[:committee_address] = nil
          hash_data[:committee_city] = nil
          hash_data[:committee_state] = nil
          hash_data[:committee_zip] = nil
        end
        hash_data[:committee_email] = row[3]
      elsif row[0].match(/Phone:/i)
        hash_data[:committee_phone] = row[1]
      end
      line_no += 1
    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def political_party(lines)
    line_no   = 0
    hash_data = {}
    hash_data[:candidate_full_name] = nil
    hash_data[:candidate_first_name] = nil
    hash_data[:candidate_last_name] = nil
    hash_data[:candidate_middle_name] = nil
    hash_data[:candidate_address] = nil
    hash_data[:candidate_phone] = nil
    hash_data[:candidate_city] = nil
    hash_data[:candidate_state] = nil
    hash_data[:candidate_zip] = nil
    hash_data[:election_date] = nil
    hash_data[:candidate_email] = nil
    hash_data[:party_affillation] = nil
    hash_data[:office_branch] = nil
    loop do
      break unless lines[line_no].presence

      row = lines[line_no].map(&:text)

      break if row[0].match(/COMMITTEE TREASURER INFORMATION/)

      if row[0].match(/INFORMATION/i)
        hash_data[:committee_id] = row.last.split.last
      elsif row[0].match(/Name of Committee/i)
        hash_data[:committee_name] = row[1]
        hash_data[:acronym] = row[3]
      elsif row[0].match(/Address/i)
        hash_data[:committee_address] = row[1]
      elsif row[0].match(/City, State and Zip:/i)
        address = row[1]
        if address
          hash_data[:committee_city] = address.split(', ')[0]
          hash_data[:committee_state] = address.split(', ')[1].split(' ')[0] rescue nil
          hash_data[:committee_zip] = address.split(', ')[1].split(' ')[1] rescue nil
        else
          hash_data[:committee_city] = nil
          hash_data[:committee_state] = nil
          hash_data[:committee_zip] = nil
        end
      elsif row[0].match(/Email:/i)
        hash_data[:committee_email] = row[1]
      elsif row[0].match(/Telephone/i)
        hash_data[:committee_phone] = row[1]
      elsif row[0].match(/Segregated/i)
        hash_data[:segregated_fund_name] = row[1]
      elsif row[0].match(/Leader/i)
        hash_data[:leader_of_legislative] = row[1]
      elsif row[0].match(/Committee Type/i)
        address = row[1]        
        hash_data[:committee_type] = row[1]
        hash_data[:committee_sub_type] = row[3]
      end
      line_no += 1
    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def sponsoring(lines)
    hash_data = {}
    hash_data[:acronym] = nil
    hash_data[:candidate_first_name] = nil
    hash_data[:candidate_last_name] = nil
    hash_data[:candidate_middle_name] = nil
    hash_data[:candidate_phone] = nil
    hash_data[:election_date] = nil
    hash_data[:candidate_email] = nil
    hash_data[:party_affillation] = nil
    hash_data[:office_branch] = nil
    hash_data[:segregated_fund_name] = nil
    hash_data[:leader_of_legislative] = nil
    hash_data[:committee_type] = nil
    hash_data[:committee_sub_type] = nil
    hash_data[:committee_address] = nil
    hash_data[:committee_city] = nil
    hash_data[:committee_state] = nil
    hash_data[:committee_zip] = nil
    line_no = 0
    row_no  = 0
    loop do
      row = lines[line_no].map(&:text)

      break if row[0].match(/DEPOSITORY INFORMATION/)

      if row[0].match(/ETH ID:/i)
        row_no = line_no
        hash_data[:committee_id] = row.last.split.last
      elsif row[0].match(/Name of Corporation/i)
        line_no += 1
        row = lines[line_no].map(&:text)
        hash_data[:candidate_full_name] = row[0]
      elsif row[0].match(/Address/i) && line_no - row_no == 3
        line_no += 1
        row = lines[line_no].map(&:text)
        hash_data[:candidate_address] = row[0]
        hash_data[:candidate_city] = row[1]
        hash_data[:candidate_state] = row[2]
        hash_data[:candidate_zip] = row[3]
      elsif row[0].match(/Name of Representative/i)
        line_no += 1
        row = lines[line_no].map(&:text)
        if row[0].match(/Address/)
          hash_data[:committee_name] = nil
          hash_data[:committee_email] = nil
          hash_data[:committee_phone] = nil
        else
          hash_data[:committee_name] = row[0]
          hash_data[:committee_email] = row[1]
          hash_data[:committee_phone] = row[2]
        end
      elsif row[0].match(/Address:/i) && line_no - row_no == 7
        line_no += 1
        row = lines[line_no].map(&:text)
        hash_data[:committee_address] = row[0]
        hash_data[:committee_city] = row[1]
        hash_data[:committee_state] = row[2]
        hash_data[:committee_zip] = row[3]
      elsif row[0].match(/Name of Separate Segregated Fund \(PAC\):/i)
        hash_data[:segregated_fund_name] = row[1]
      elsif row[0].match(/Date Fund \(PAC\) Registered/i)
        hash_data[:election_date] = Date.strptime(row[1], '%m/%d/%Y') rescue nil
      end
      line_no += 1
    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def conduit(lines)
    hash_data = {}
    hash_data[:candidate_first_name] = nil
    hash_data[:candidate_last_name] = nil
    hash_data[:candidate_middle_name] = nil
    hash_data[:candidate_phone] = nil
    hash_data[:election_date] = nil
    hash_data[:candidate_email] = nil
    hash_data[:party_affillation] = nil
    hash_data[:office_branch] = nil
    hash_data[:segregated_fund_name] = nil
    hash_data[:leader_of_legislative] = nil
    hash_data[:committee_type] = nil
    hash_data[:committee_sub_type] = nil
    line_no = 0
    loop do
      row = lines[line_no].map(&:text)
      
      break if row[0].match(/DEPOSITORY INFORMATION/)

      if row[0].match(/CONDUIT INFORMATION/i)
        row_no = line_no
        hash_data[:committee_id] = row.last.split.last
      elsif row[0].match(/Name of Conduit/i)
        hash_data[:candidate_full_name] = row[1]
        hash_data[:acronym] = row[3]
      elsif row[0].match(/Address \(City State Zip\):/i)
        address = row[1]
        if address
          address = address.split(', ')
          address_line = address.count == 4 ? "#{address[0]}, #{address[1]}" : address[0]
          city = address.count == 4 ? address[2] : address[1]
          hash_data[:candidate_address] = address_line
          hash_data[:candidate_city] = city
          hash_data[:candidate_state] = address.last.split(' ')[0]
          hash_data[:candidate_zip] = address.last.split(' ')[1]
        else
          hash_data[:candidate_address] = nil
          hash_data[:candidate_city] = nil
          hash_data[:candidate_state] = nil
          hash_data[:candidate_zip] = nil
        end
      elsif row[0].match(/Name of Administrator:/i)
        hash_data[:committee_name] = row[1]
        hash_data[:committee_phone] = row[3]
      elsif row[0].match(/Address:/i)
        address = row[1]
        if address
          address = address.split(', ')
          address_line = address.count == 4 ? "#{address[0]}, #{address[1]}" : address[0]
          city = address.count == 4 ? address[2] : address[1]
          hash_data[:committee_address] = address_line
          hash_data[:committee_city] = city
          hash_data[:committee_state] = address.last.split(' ')[0]
          hash_data[:committee_zip] = address.last.split(' ')[1]
        else
          hash_data[:committee_address] = nil
          hash_data[:committee_city] = nil
          hash_data[:committee_state] = nil
          hash_data[:committee_zip] = nil
        end
      elsif row[0].match(/Email:/i)
        hash_data[:committee_email] = row[1]
      end
      line_no += 1
    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def ethics_commission(lines)
    hash_data = {}
    line_no   = 0
    loop do

    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def indpendent_expenditure(lines)
    hash_data = {}
    line_no   = 0
    loop do

    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def unregistered_express(lines)
    hash_data = {}
    line_no   = 0
    loop do

    end
    hash_data[:data_source_url] = @file_path
    hash_data.merge(md5_hash: create_md5_hash(hash_data))
  end

  def parse_page_data(page)
    receiver = PDF::Reader::PageTextReceiver.new
    page.walk(receiver)    
    runs = receiver.runs.sort { |r1, r2| (res = r1.y.to_i <=> r2.y.to_i).zero? ? r1.x <=> r2.x : res }
    runs.each_with_index do |run, run_idx|
      next_run_idx = runs.find_index do |r|
        r.present? &&
        run.font_size.round == r.font_size.round &&
        (run.x - r.x).abs <= 2 &&
        (r.y - run.endy).abs <= 3
      end
    
      unless next_run_idx.nil?
        next_run = runs[next_run_idx]
        joint = next_run.text.match?(/\-$/) ? '' : ' '
        new_text = [next_run.text, run.text].join(joint)
        runs[next_run_idx] = PDF::Reader::TextRun.new(next_run.x, next_run.y, next_run.width, next_run.font_size, new_text)
        runs[run_idx] = nil
      end
    end
    runs.compact.sort_by { |r| -r.y }.chunk_while { |r1, r2| (r1.y - r2.y).abs <= 2 }.map { |r| r.sort_by { |ir| ir.x } }
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end


# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    @contrib_headers  = nil
    @expendit_headers = nil
  end

  def parse_all_dump_html(html)
    doc = Nokogiri::HTML(html)

    all_files  = doc.xpath('//table[1]/tbody/tr/th/a').map { |el| el[:href] }
    cont_files = []
    exp_files  = []

    all_files.each do |file_name|
      match_data = file_name.match(/^(\d{4})_mi_cfr_contributions(?:_(\d+))?\.zip$/)
      if (match_data&.size || 0) >= 2
        cont_files << {
          year:  match_data[1].to_i,
          order: match_data[2].to_i,
          file:  file_name
        }
      end

      match_data = file_name.match(/^(\d{4})_mi_cfr_expenditures(?:_(\d+))?\.zip$/)
      if (match_data&.size || 0) >= 2
        exp_files << {
          year:  match_data[1].to_i,
          order: match_data[2].to_i,
          file:  file_name
        }
      end
    end

    if cont_files.blank? || exp_files.blank?
      logger.info 'Failed to parse the file list.'
      logger.info html
      raise 'Failed to parse the file list.'
    end

    [
      Hash[
        cont_files
          .group_by { |e| e[:year] }
          .sort_by { |k, _| k }
          .map { |e| [e[0], e[1].sort_by { |e1| e1[:order] }.map { |e1| e1[:file] }] }
      ],
      Hash[
        exp_files
          .group_by { |e| e[:year] }
          .sort_by { |k, _| k }
          .map { |e| [e[0], e[1].sort_by { |e1| e1[:order] }.map { |e1| e1[:file] }] }
      ]
    ]
  end

  def parse_candidate_file(file_path)
    can_keys = {
      'Statement Year'              => :statement_year,
      'Committee ID#'               => :committee_id,
      'Document Sequence#'          => :doc_seq_num,
      'Committee Type'              => :committee_type,
      'Committee Name'              => :committee_name,
      'Candidate Last Name'         => :last_name,
      'Candidate First Name'        => :first_name,
      'Candidate Middle Name'       => :middle_name,
      'Political Party Affiliation' => :party,
      'Office Sought'               => :position_sought,
      'District Sought'             => :district
    }

    parse_csv_zip(file_path, can_keys, nil) do |data|
      data[:full_name] = [data[:first_name], data[:middle_name], data[:last_name]].compact.join(' ')
      data[:state] = 'MI'
      yield data
    end
  end

  def parse_committee_file(file_path)
    comm_keys = {
      'Committee Name (MaxLen=72)'        => :committee_name,
      'Bureau Committee ID# (MaxLen=6)'   => :committee_number,
      'District Sought (MaxLen=80)'       => :district,
      'Political Party (MaxLen=48)'       => :party,
      'Office Sought (MaxLen=80)'         => :office_sought,
      'Committee Formed Date (MaxLen=10)' => :formed_date,
      'SofO Received Date (MaxLen=10)'    => :sofo_date,
      'Mailing Address (MaxLen=62)'       => :contact_address,
      'Mailing City (MaxLen=20)'          => :contact_city,
      'Mailing State (MaxLen=2)'          => :contact_state,
      'Mailing Zipcode (MaxLen=10)'       => :contact_zip,
      'Phone# (MaxLen=10)'                => :contact_phone
    }

    parse_csv_text(file_path, comm_keys, nil) do |data|
      form_date = data.delete(:formed_date)
      sofo_date = data.delete(:sofo_date)
      form_date = Date.strptime(form_date, '%m/%d/%Y') rescue nil
      sofo_date = Date.strptime(sofo_date, '%m/%d/%Y') rescue nil
      form_year = form_date&.year
      sofo_year = sofo_date&.year
      data[:election_year] = [form_year, sofo_year].compact.max

      yield data
    end
  end

  def parse_contribution_file(file_path)
    contrib_keys = {
      'doc_seq_no'      => :doc_seq_num,
      'page_no'         => :page_no,
      'contribution_id' => :contributor_id,
      'cont_detail_id'  => :cont_detail_id,
      'doc_stmnt_year'  => :doc_stmnt_year,
      'doc_type_desc'   => :doc_type_desc,
      'com_legal_name'  => :committee_name,
      'com_type'        => :committee_type,
      'cfr_com_id'      => :committee_id,
      'contribtype'     => :type,
      'received_date'   => :date,
      'amount'          => :amount,
      'f_name'          => :first_name,
      'l_name_or_org'   => :last_name,
      'address'         => :address,
      'city'            => :city,
      'state'           => :state,
      'zip'             => :zip,
      'employer'        => :employer,
      'occupation'      => :job_title
    }

    @contrib_headers =
      parse_csv_zip(file_path, contrib_keys, @contrib_headers) do |data|
        first_name = data.delete(:first_name)
        last_name  = data.delete(:last_name)
        data[:name] = [first_name, last_name].compact.join(' ')
        data[:date] = parse_date(data[:date])

        contribution = data.select do |k, _|
          %i[
            doc_seq_num page_no contributor_id cont_detail_id doc_stmnt_year
            doc_type_desc committee_name committee_type committee_id type date amount
          ].include?(k)
        end

        contributor = data.select do |k, _|
          %i[
            doc_seq_num page_no contributor_id cont_detail_id doc_stmnt_year
            doc_type_desc name address city state zip employer job_title
          ].include?(k)
        end

        yield contribution, contributor
      end
  end

  def parse_expenditure_file(file_path)
    exp_keys = {
      'doc_seq_no'       => :doc_seq_num,
      'expenditure_type' => :expenditure_type,
      'page_no'          => :page_num,
      'exp_date'         => :date,
      'expense_id'       => :payee_id,
      'detail_id'        => :detail_id,
      'doc_stmnt_year'   => :doc_stmnt_year,
      'doc_type_desc'    => :doc_type_desc,
      'f_name'           => :first_name,
      'lname_or_org'     => :last_name,
      'amount'           => :amount,
      'com_legal_name'   => :committee_name,
      'cfr_com_id'       => :committee_id,
      'exp_desc'         => :expense_description,
      'purpose'          => :expense_purpose,
      'extra_desc'       => :extra_expense_description,
      'address'          => :address,
      'city'             => :city,
      'county'           => :county,
      'state'            => :state,
      'zip'              => :zip,
      'state_loc'        => :state_loc,
      'supp_opp'         => :support_oppose,
      'can_or_ballot'    => :candidate_or_ballot,
      'debt_payment'     => :debt_payment,
      'vend_name'        => :vend_name,
      'vend_addr'        => :vend_addr,
      'vend_city'        => :vend_city,
      'vend_state'       => :vend_state,
      'vend_zip'         => :vend_zip,
      'gotv_ink_ind'     => :gotv_ink_ind
    }

    @expendit_headers =
      parse_csv_zip(file_path, exp_keys, @expendit_headers) do |data|
        first_name = data.delete(:first_name)
        last_name  = data.delete(:last_name)
        data[:payee_name] = [first_name, last_name].compact.join(' ')
        data[:date] = parse_date(data[:date])
        data[:type] = 'Expenditure'
        data[:expense_category] = 'Expenditure'
        data[:expense_method] = 'check'
        yield data
      end
  end

  private

  def parse_csv_stream(stream, keys, header_indice)
    while true
      line = stream.readline rescue nil
      break if line.nil?

      line = line.force_encoding('iso-8859-1').encode('utf-8')
      line = line.gsub(/(?:\r|\n|\r\n)$/, '')
      data = line.split("\t", -1).map { |item| item.strip.gsub(/^"|"$/, '').presence }

      if (keys.keys - data).size.zero?
        header_indice =
          keys.each_with_object({}) do |(k, _), hash|
            hash[k] = data.find_index(k)
          end
      elsif header_indice.present?
        data_map =
          keys.each_with_object({}) do |(k, v), hash|
            hash[v] = data[header_indice[k]]
            hash[v] = nil if hash[v].blank?
          end

        bad = data_map.compact.keys.count < 0.5 * keys.count
        yield(data_map) unless bad
      end
    end
  end

  def parse_csv_text(file_path, keys, header_indice, &block)
    File.open(file_path, 'r') do |file|
      header_indice = parse_csv_stream(file, keys, header_indice, &block)
    end

    header_indice
  end

  def parse_csv_zip(file_path, keys, header_indice, &block)
    Zip::File.foreach(file_path) do |entry|
      entry.get_input_stream do |stream|
        header_indice = parse_csv_stream(stream, keys, header_indice, &block)
      end
    end

    header_indice
  end

  def parse_date(date_string)
    dt = Date.strptime(date_string, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
    dt ||= Date.strptime(date_string, '%m/%d/%Y').strftime('%Y-%m-%d') rescue nil
    dt
  end
end

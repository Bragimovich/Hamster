# frozen_string_literal: true

class PacerMD5
  MD5 = {
    info:       %i[court_id case_name case_id case_filed_date case_description case_type disposition_or_status status_as_of_date judge_name],
    info_root2:       %i[court_id case_name case_id case_filed_date case_description case_type disposition_or_status status_as_of_date judge_name],
    info_root:       %i[court_id case_name case_id case_filed_date case_description case_type disposition_or_status status_as_of_date judge_name],
    party:      %i[court_id case_id party_name party_type],
    party_root2:      %i[court_id case_id party_name party_type],
    party_root: %i[court_id case_number party_name party_type],
    activities: %i[court_id case_id activity_date activity_decs activity_pdf],
    activities_root2: %i[court_id case_id activity_date activity_decs activity_pdf],
    activities_root: %i[court_id case_id activity_date activity_decs activity_pdf],
    lawyer_root: %i[court_id case_number defendant_lawyer defendant_lawyer_firm plantiff_lawyer plantiff_lawyer_firm]
  }
  
  attr_reader :hash, :columns
  
  # @param data [Hash] with symbols in keys
  # @param table [Symbol] one of :info, :party, :activities
  #
  # @example
  #   data = { court_id: 5, case_id: 14, party_name: 'Maxim', party_type: 'person' }
  #   md5 = PacerMD5.new(data: data, table: :party)
  #   p md5.hash
  def initialize(data:, table:)
    error_message = "Wrong value for param :table in PacerMD5#new. You should use one from following: :#{MD5.keys.join(', :')}"
    raise error_message unless MD5.keys.include?(table.to_sym) #todo: make opportunity to make your own array of columnname

    @data    = data
    @columns = MD5[table.to_sym]
    value_correction(table)
    @hash    = generate_md5
  end
  
  private

  def value_correction(table)
    @data[:activity_date]='0000-00-00' if ['activities',:activities].include?(table) and (@data[:activity_date]=='' or @data[:activity_date]==nil) # default in db '0000-00-00' but in reading or writing data can be nill
  end
  
  def generate_md5
    all_values_str = ''
    @columns.each do |key|
      if @data[key].nil?
        all_values_str = all_values_str + @data[key.to_s].to_s
      else
        all_values_str = all_values_str + @data[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end
end

require_relative '../models/case_numbers'
require_relative '../models/il_dupage_case_runs'
require_relative '../models/il_dupage_case_info'
require_relative '../models/il_dupage_case_party'
require_relative '../models/il_dupage_case_activities'
require_relative '../models/il_dupage_case_pdfs_on_aws'
require_relative '../models/il_dupage_case_relations_info_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(IlDupageCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_case_info(name, data_array)
    model = name.constantize
    (data_array[0].nil?)?  model.insert(data_array) : model.insert_all(data_array)  unless data_array.empty?
  end

  def fetch_party_info(case_id)
    CaseNumbers.where(:case_number => case_id)
  end

  def fetch_case_numbers
    CaseNumbers.pluck(:case_number)
  end

  def fetch_case_id
    CaseInfo.pluck(:case_id)
  end

  def fetch_change
    case_numbers = CaseNumbers.group(:case_number).count
    party_case_numbers = CaseParty.group(:case_id).count
    case_numbers_with_different_count = []
    case_numbers.each do |num|
      next if party_case_numbers[num.first].nil?
      if party_case_numbers[num.first] < num.last
        case_numbers_with_different_count << num.first
      end
    end
    case_numbers_with_different_count
  end

  def get_last_page(letter)
    CaseNumbers.where(:search_letter => letter).pluck(:page_no).max rescue nil
  end

  def fetch_last_name
    CaseNumbers.pluck(:full_last_name)
  end
end

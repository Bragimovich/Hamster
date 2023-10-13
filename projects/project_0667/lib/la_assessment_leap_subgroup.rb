require_relative '../lib/common_methods'

module LaAssessmentLeapSubgroup

  include CommomMethods

  def parsing_subgroup(path, file, la_info_data, link)
    data_array = []
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx_file.nil?

    flag = true
    number = ''
    @school_year = path.split('/')[-2].gsub('_', '-')
    xlsx_file.sheet( xlsx_file.sheets[0]).each do |row|
      flag = false if !row[0].nil? and row[0] == 'State'
      next if flag

      if row[1].length < 4
        number = row[1]
      end
      @general_id, la_info_data = get_general_id(la_info_data, row[1..])
      @grade = row[5]
      @subgroup = row[6]
     data_array << get_sub_group_hash('English Language Arts', row[7..11], link)
     data_array <<  get_sub_group_hash('Mathematics', row[12..16], link)
      if row.count == 27
        data_array <<  get_sub_group_hash('Science', row[17..21], link)
        data_array <<  get_sub_group_hash('Social Studies', row[22..26], link)
      end

      if row.count == 22
        data_array << get_sub_group_hash('Social Studies', row[17..21], link)
      end
    end
    data_array
  end

  private

  def get_sub_group_hash(subject, data, link)
    hash = {}
    hash[:grade] = @grade
    hash[:general_id] = @general_id
    hash[:data_source_url] = link[0]
    hash[:subject] = subject
    hash[:subgroup] = @subgroup
    hash[:school_year] = @school_year
    hash[:advanced_percent] = data[0].squish
    hash[:mastery_percent] = data[1].squish
    hash[:basic_percent] = data[2].squish
    hash[:approaching_basic_percent] = data[3].squish
    hash[:unsatisfactory_percent] = data[4].squish
    hash = commom_hash_info(hash)
    hash
  end
end

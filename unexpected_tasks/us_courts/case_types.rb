# frozen_string_literal: true

require_relative 'transfer_cases/us_cases'

module UnexpectedTasks
  module UsCourts
    class CaseTypes
      def self.run(**options)
        make_table_case_type_category_id if options[:make_table]
        days = options[:days]
        types(days)
      end
    end
  end
end


def types(days=5)
  days = 365 if days.nil?
  case_type_to_id = {}
  CaseTypeCategoryId.all().map { |row| case_type_to_id[row.name] = row.id }

  limit = 3000
  page = 0
  loop do
    p page

    offset = limit * page

    cases = UsCaseInfoCourts.select(:case_id, :case_type, :court_id).limit(limit).offset(offset).where("Date(updated_at)>'#{Date.today()-days}'")
    case_types = cases.map { |row| row.case_type }

    case_ids = []
    court_ids = []
    cases.each do |the_case|
      case_ids.push(the_case.case_id)
      court_ids.push(the_case.court_id) if !the_case.court_id.in?(court_ids)
    end

    existed_case_ids = CaseTypeCategory.where(court_id:court_ids).where(case_id:case_ids).map { |row| row.case_id }

    hash_id_by_type = get_id_for_case_type(case_types, case_type_to_id) #get_ids_by_case_type(case_types)
    case_type_categories = []
    cases.each do |row|
      next if row.case_id.in?(existed_case_ids) or row.case_type.nil?
      next if hash_id_by_type[row.case_type.downcase].nil?

      hash_id_by_type[row.case_type.downcase].each do |id|
        case_type_categories.push(
          {case_id: row.case_id, court_id: row.court_id, case_type_category_id:id}
        )
      end

    end
    p "Length: #{case_type_categories.length}"
    CaseTypeCategory.insert_all(case_type_categories) unless case_type_categories.empty?
    page+=1
    break if cases.to_a.length<limit
  end
end


def get_ids_by_case_type(case_types)
  hash_id_by_type = {}
  CaseTypeCategory.where(name:case_types).each do |ct|
    if ct.name.in? hash_id_by_type.keys
      hash_id_by_type[ct.name.downcase].push(ct.id)
    else
      hash_id_by_type[ct.name.downcase] = [ct.id]
    end

  end
  hash_id_by_type
end


def get_id_for_case_type(case_types, case_type_to_id)
  hash_case_types = {}

  type_name = []
  case_types_divided = CaseTypesDivided.where(values: case_types)

  case_types_divided.each do |row|
    hash_case_types[row.values.downcase] = []
    hash_case_types[row.values.downcase].push(case_type_to_id[row.general_category]) unless row.general_category.nil?
    hash_case_types[row.values.downcase].push(case_type_to_id[row.midlevel_category]) unless row.midlevel_category.nil?
    hash_case_types[row.values.downcase].push(case_type_to_id[row.specific_category]) unless row.specific_category.nil?
  end
  hash_case_types
end


def make_table_case_type_category_id
  limit = 100
  page = 0
  loop do
    p page

    offset = limit * page

    case_types = CaseTypesDivided.limit(limit).offset(offset)

    new_case_types = []
    existing_category_name = []

    categories = {general_category: "General Category", midlevel_category: "Mid-level Category", specific_category: "Specific Categoriy"}
    case_types.each do |row|
      categories.keys.each do |category_name|
        if !row[category_name].nil?
          new_case_types.push(
            {name: row[category_name], category: categories[category_name], }
          )
          existing_category_name.push(row[category_name])
        end
      end
    end

    begin
      CaseTypeCategoryId.insert_all(new_case_types) unless new_case_types.empty?
    rescue => e
      p e
      escape_with_existing_category_name(new_case_types, existing_category_name)
    end
    page +=1
    break if case_types.to_a.length<limit
  end

end


def escape_with_existing_category_name(new_case_types, existing_category_name)

        existing_category_name = CaseTypeCategory.where(name: existing_category_name).map {|row| row.name}

        new_case_types.each do |case_type|
          next if case_type.name.in?(existing_category_name)
          CaseTypeCategory.create(case_type)
        end
end


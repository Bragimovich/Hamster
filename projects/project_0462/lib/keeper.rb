# frozen_string_literal: true

require_relative '../models/organizations'

class Keeper < Hamster::Harvester
  def csv_to_db(filename, table)
    res = Organization.connection.execute("show columns from `#{table}`;").to_a
    col_names = res.map { |el| el[0] }[1..-4] # return column names without `id`, `created_by`, `created_at`, `updated_at`
    query = <<~SQL
      LOAD DATA LOCAL INFILE '#{filename}'
          INTO TABLE `#{table}`
          FIELDS TERMINATED BY ',' ENCLOSED BY '"'
          LINES TERMINATED BY '\n'
          (#{col_names.map {|el| "@p#{col_names.find_index(el).succ},"}.join[0..-2]})
          SET #{col_names.map {|el| "#{el} = @p#{col_names.find_index(el).succ},\n"}.join}
      SQL
    puts '*'*77, query[0..-4]
    Organization.connection.execute(query[0..-4])
  end

  def get_orgs
    res = Organization.connection.execute('SELECT org_id from `opensecrets__organizations`')
    orgs = []
    res.each do |el|
      org_id = el[0]
      org_data = {
        id: org_id,
        link: "#{URL}/orgs/totals?id=#{org_id}&totalsaffilcycle=#{CYCLE}"
      }
      orgs << org_data
    end
    orgs
  end
end

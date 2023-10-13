class Parser < Hamster::Parser
  def initialize(**option)
    @csv  = option[:csv]
    @csv_inflow_outflow = option[:csv_inflow_outflow]
  end

  def parse_csv(years, general_url)
    values = @csv.split("\n")[1..-1]
    not_total_values    = []
    values.each do |row|
      arr_every_one     = row.split(',')
      not_total_values << arr_every_one unless arr_every_one[3].to_i == 0
    end

    keys         = [:number_of_returns, :number_of_individuals, :agi_1, :agi_2]
    return_types = ['Total returns',
                    'Non-migrant returns',
                    'Outflow returns',
                    'Inflow Returns',
                    'Same State returns',
                   ]
    ages         = [[0, 100],
                    [0, 26],
                    [26, 35],
                    [35, 45],
                    [45, 55],
                    [55, 65],
                    [65, 100]
                   ]
    amounts      = ['$1 under $10,000',
                    '$10,000 under $25,000',
                    '$25,000 under $50,000',
                    '$50,000 under $75,000',
                    '$75,000 under $100,000',
                    '$100,000 under $200,000',
                    '$200,000 or more'
                   ]

    for_db                    = [] #<<irs_gross_migration_to_h
    not_total_values.each do |row|
      row.delete_at(2)
      start_data                   = {}
      start_data[:year_1]          = years[0]
      start_data[:year_2]          = years[1]
      start_data[:state_fips]      = row.delete_at(0)
      start_data[:state]           = row.delete_at(0)
      start_data[:amounts]         = amounts[row.delete_at(0).to_i - 1]
      start_data[:data_source_url] = general_url
      [*0..return_types.size - 1].each do |i|
        return_type_raw            = row.slice!(0, 28)
        return_type                = return_types[i]
        [*0..6].each do |age|
          age_type                 = ages[age]
          end_data                 = {}
          return_type_raw.slice!(0, 4).each_with_index do |amount, idx|
            end_data[keys[idx]]  = amount
          end
          end_data[:return_type]   = return_type
          end_data[:age_1]         = age_type[0]
          end_data[:age_2]         = age_type[1]
          for_db << end_data.merge(start_data)
        end
      end
    end
    for_db
  end

  def parse_csv_inflow_outflow(years, general_url)
    inflow_values = @csv_inflow_outflow.split("\n")[1..-1].map {|string| string.split(',')}
    irs_state_inflow                       = []
    inflow_values.each do |row|
      data_titles                          = {}
      data_titles[:year_1]                 = years[0]
      data_titles[:year_2]                 = years[1]
      data_titles[:origin_state_fips]      = row[0]
      data_titles[:destination_state_fips] = row[1]
      data_titles[:destination_state_name] = row[3]
      data_titles[:number_of_returns]      = row[4]
      data_titles[:number_of_exemptions]   = row[5]
      data_titles[:adjusted_gross_income]  = row[6]
      data_titles[:data_source_url]        = general_url
      irs_state_inflow << data_titles
    end
    irs_state_inflow
  end
end

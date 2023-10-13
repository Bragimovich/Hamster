class Parser < Hamster::Parser
  def parse(json)
    data_info = []
    data = json['data']
    data.each do |elem|
      info                         = {}
      organ_programm               = elem['name'].split('-')
      created                      = elem['createdTs'].split('/')
      updated                      = elem['updatedTs'].split('/')
      info[:organization]          = organ_programm[0].strip
      info[:program]               = organ_programm[1].strip rescue nil
      info[:state]                 = elem['stateObj']['abbreviation']
      info[:category]              = elem['categoryObj']['name']
      info[:policy_incentive_type] = elem['typeObj']['name']
      info[:created]               = Date.parse(created[1] + '/' + created[0] + '/' + created[2]) rescue nil
      info[:updated]               = Date.parse(updated[1] + '/' + updated[0] + '/' + updated[2]) rescue nil
      info[:data_source_url]       = elem['websiteUrl'].empty? ? nil : elem['websiteUrl'] rescue nil
      info[:scrape_year]           = Time.now.year
      info[:created_by]            = 'Halid Ibragimov'
      data_info << info
    end
    data_info
  end
end

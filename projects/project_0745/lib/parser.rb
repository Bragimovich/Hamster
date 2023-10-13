class Parser < Hamster::Parser
  def parse(body)
    teg       = body.css("#ctl00_cphMain_pnlResult > table > tbody > tr:nth-child(3) > td > table tr")
    info      = []
    candidate = {}
    teg[1..-1]&.each_with_index do |elem, i|
      elem.css('td')[0].text rescue next
      if elem.css('td')[0].text[-1] == ' '
        candidate.clear
        candidate[:full_name]   = elem.css('td')[0].text.strip
        candidate[:age]         = elem.css('td')[1].text
        candidate[:inmate_id]   = elem.css('td')[2].text
        candidate[:term_id]     = elem.css('td')[3].text
        booked_date             = elem.css('td')[4].text.split('/')
        maxed                   = elem.css('td')[5].text.split('/')
        candidate[:booked_date] = booked_date[1] + '-' + booked_date[0] + '-' + booked_date[2]
        candidate[:maxed]       = maxed[1] + '-' + maxed[0] + '-' + maxed[2]
        candidate[:facility]    = elem.css('td')[6].text
      else
        elem.css('td')[0].text.to_i > 0 ? table = elem.css('td') : next rescue next
        candidate_val                = {}
        candidate_val[:case_id]      = table.css('td')[0].text
        offence_date                 = table.css('td')[1].text.split('/')
        minimum                      = table.css('td')[2].text.split('/')
        maximum                      = table.css('td')[3].text.split('/')
        candidate_val[:offence_date] = offence_date[1] + '-' + offence_date[0] + '-' + offence_date[2]
        candidate_val[:minimum]      = minimum[1] + '-' + minimum[0] + '-' + minimum[2]
        candidate_val[:maximum]      = maximum[1] + '-' + maximum[0] + '-' + maximum[2]
        candidate_val[:docket]       = table.css('td')[4].text
        candidate_val[:court]        = table.css('td')[5].text
        info << candidate.merge(candidate_val)
      end
    end
    info.uniq!
    info.each do |inform|
      md5 = MD5Hash.new(columns: inform.keys)
      inform[:md5_hash] = md5.generate(inform)
    end
    binding.pry
  end
end

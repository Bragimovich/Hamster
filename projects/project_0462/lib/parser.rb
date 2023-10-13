# frozen_string_literal: true

class Parser < Hamster::Parser
  def get_number(str)
    str.gsub(/\D/, '').to_i * (str[0] == '-' ? -1: 1)
  end

  def get_orgs(source)
    res = []
    page = Nokogiri::HTML source.body
    body = page.css('body').text
    orgs = JSON.parse(body)['response']['organization']
    orgs = [orgs] if orgs.instance_of?(Hash)
    orgs.each { |org| res << org['@attributes'].merge(url: source.env.url.to_s) }
    res
  end

  def get_recipients(source, donor)
    res = []
    page = Nokogiri::HTML source.body
    thead = page.css('thead')[-1]
    return res if !thead # check if no tables with head

    return res if thead.css('th')[0].text != 'Recipient' # check if table with head isn't the recipients table

    tbody = page.css('tbody')[-1]
    return res if !tbody # check if recipients table is empty

    table = tbody.css('tr')

    table.each do |record|
      fields = record.css('td').map { |el| el.text.strip }
      recipient_data = {
        donor_id:   donor[:id],
        recipient:  fields[0],
        total:      get_number(fields[1]),
        from_ind:   get_number(fields[2]),
        from_org:   get_number(fields[3]),
        rec_type:   fields[4],
        view:       fields[5],
        type:       fields[6],
        chamber:    fields[7],
        cycle:      "#{CYCLE}",
        url:        donor[:link]
      }
      res << recipient_data
    end
    res
  end

  def get_by_party(source, donor)
    res = []
    page = Nokogiri::HTML source.body
    thead = page.css('thead')[0]
    return res if !thead # check if no tables with head

    return res if thead.css('th')[2].text != 'Democrats' # check if table with head isn't the contributions_by_party table

    tbody = page.css('tbody')[0]
    return res if !tbody # check if table is empty

    table = tbody.css('tr')
    table.each do |record|
      fields = record.css('td').map { |el| el.text.strip }
      contributions_by_party_data = {
        donor_id:   donor[:id],
        cycle:      fields[0],
        total:      get_number(fields[1]),
        dems:       get_number(fields[2]),
        d_percent:  fields[3][0..-2],
        reps:       get_number(fields[4]),
        r_percent:  fields[5][0..-2],
        url:        donor[:link]
      }
      res << contributions_by_party_data
    end
    res
  end

  def get_by_funds(source, donor)
    res = []
    page = Nokogiri::HTML source.body
    thead = page.css('thead')[1]
    return res if !thead # check if no tables with head

    return res if thead.css('th')[3].text != 'Soft (Individuals)' # check if table with head isn't the contributions_by_party table

    tbody = page.css('tbody')[1]
    return res if !tbody # check if table is empty

    table = tbody.css('tr')
    table.each do |record|
      fields = record.css('td').map { |el| el.text.strip }
      contributions_by_source_data = {
        donor_id:   donor[:id],
        cycle:      fields[0],
        ind:        get_number(fields[1]),
        pacs:       get_number(fields[2]),
        soft_ind:   get_number(fields[3]),
        soft_org:   get_number(fields[4]),
        url:        donor[:link]
      }
      res << contributions_by_source_data
    end
    res
  end

  def get_affiliates(source, donor)
    res = []
    page = Nokogiri::HTML source.body
    thead = page.css('thead')[1]
    return res if !thead # check if no tables with head

    return res if thead.css('th')[0].text != 'Affiliate' # check if table with head isn't the contributions_affiliates table

    tbody = page.css('tbody')[1]
    return res if !tbody # check if table is empty

    table = tbody.css('tr')
    table.each do |record|
      fields = record.css('td').map { |el| el.text.strip }
      affiliates_data = {
        donor_id:   donor[:id],
        affiliate:  fields[0],
        total:      get_number(fields[1]),
        dems:       get_number(fields[2]),
        d_percent:  fields[3][0..-2],
        reps:       get_number(fields[4]),
        r_percent:  fields[5][0..-2],
        pacs:       get_number(fields[6]),
        individuals:get_number(fields[7]),
        cycle:      CYCLE,
        url:        donor[:link]
      }
      res << affiliates_data
    end
    res
  end
end

# frozen_string_literal: true

require_relative '../models/us_courts_or_model'

class Keeper < Hamster::Harvester
  def store_items(items)
    ORCaseApiItems.insert_all(items)
  end

  def api_links
    puts '*'*77, sql = 'SELECT itemLink from or_saac_case_api_items;'
    res = ORCaseApiItems.connection.execute(sql).to_a.flatten
    res.map {|el| singleitem(el)}
  end

  def singleitem(api_link)
    api_link.sub('compoundobject','singleitem')
  end

  def store(the_case)
    md5_info = MD5Hash.new(table: :info)
    the_case[:info][:data_source_url] = the_case[:activities][:file]
    the_case[:info][:md5_hash] = md5_info.generate(the_case[:info])

    md5_party = MD5Hash.new(table: :party)
    the_case[:parties].each_index do |i|
      the_case[:parties][i][:data_source_url] = the_case[:info][:data_source_url]
      the_case[:parties][i][:party_law_firm] = the_case[:info][:data_source_url][..1022]
      the_case[:parties][i][:md5_hash] = md5_party.generate(the_case[:parties][i])
    end

    md5_activities = MD5Hash.new(:columns => %w(court_id case_id activity_date activity_type activity_desc file data_source_url))
    the_case[:activities][:data_source_url] = the_case[:info][:data_source_url]
    the_case[:activities][:md5_hash] = md5_activities.generate(the_case[:activities])

    ORCaseInfo.insert(the_case[:info])
    ORCaseParty.insert_all(the_case[:parties]) unless the_case[:parties].empty?
    ORCaseActivities.insert(the_case[:activities])
  end
end

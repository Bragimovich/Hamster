# frozen_string_literal: true

class Keeper < Hamster::Scraper

  def initialize(leg_id)
    super
    @leg_id = leg_id
  end

  def insert_all(data)
    table_sym = :texts
    begin
      DBModels.each_key do |table|
        table_sym = table.to_sym

        if !data[table_sym].nil?
          if !data[table_sym].empty?
            insert_data_to_table(data[table_sym], table_sym)
            mark_deleted(data[table_sym], table_sym)
          end
        end
      end
    rescue => e
      p e
      DBModels.each_key do |table_to_delete|
        delete_all(table_to_delete)
        break if table_to_delete == table_sym
      end
    end

  end

  DBModels = {
    info: CongressionalLegislationInfo, actions:CongressionalLegislationActions,
    actions_overview: CongressionalLegislationActionsOverview, committees: CongressionalLegislationCommittees,
    cosponsors: CongressionalLegislationCosponsors, related_bills: CongressionalLegislationRelatedBills,
    subjects: CongressionalLegislationSubjects, texts: CongressionalLegislationTexts,
  }

  def mark_deleted(data, table)
    congress = data[0][:congress]
    leg_id   = data[0][:leg_id]

    md5_hashes = []
    data.map { |row| md5_hashes.push(row[:md5_hash]) }
    p md5_hashes
    if table==:texts
      p 'hi'
    end
    DBModels[table].where(leg_id:leg_id).where(congress:congress).where.not(md5_hash:md5_hashes).update(deleted:1)
    DBModels[table].where(md5_hash:md5_hashes).update(deleted:0)
  end


  def insert_data_to_table(data, table)

    DBModels[table].insert_all(data) if !data.empty?


    #   if data.class==Array
    #     data.each do |leg|
    #       p leg
    #       DBModels[table].insert(leg)
    #     end
    #   end
    # end
  end



  def delete_all(table)
    DBModels[table].where(leg_id:@leg_id).destroy_all
  end

  def self.get_existing_legs(leg_ids, congress)
    existion_legislation = []

    legislations = CongressionalLegislationInfo.where("congress_number like '#{congress}th Congress%'").where(leg_id:leg_ids)
    legislations.each {|row| existion_legislation.push(row[:leg_id])}
    existion_legislation
  end

  def check_existing_committees(committee)
    if CongressionalLegislationCommitteesFederalSites.where(committee_name:committee).first.nil?
      CongressionalLegislationCommitteesFederalSites.insert(committee_name:committee)
    end
  end



end

def existing_text(leg_ids)
  existings = []
  CongressionalLegislationTexts.where(leg_id:leg_ids).map { |row| existings.push(row.leg_id) }
  existings
end
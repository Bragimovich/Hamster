# frozen_string_literal: true

class LegislationMatcher < Hamster::Scraper

  def initialize(*_)
    p 'hi'
    start
  end

  def start
    CongressionalLegislationSponsorsFederalSites.all().each do |sponsor|
      q = 0
      CongressionalRecordHouseRPMembers.where("YEAR(end_term)>2019").where(first_name:sponsor.first_name).where(last_name:sponsor.last_name).each do |senate|
        sponsor.bioguide = senate.bioguide
        sponsor.member = 'house'
        q = 1
      end
      CongressionalRecordSenateMembers.where("YEAR(end_term)>2019").where(first_name:sponsor.first_name).where(last_name:sponsor.last_name).each do |senate|
        sponsor.bioguide = senate.bioguide
        sponsor.member = 'senate'
        p senate.full_name if q==1
      end
      sponsor.save

    end

  end

end

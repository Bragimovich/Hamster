require 'google_drive'
require_relative '../models/race'
require_relative '../models/candidate'
require_relative '../models/candidate_old'

class ParserSpreadsheet < Hamster::Parser
  def initialize
    super
    @session     = GoogleDrive::Session.from_service_account_key('token-eldar.json')
    @db01        = Mysql2::Client.new(Storage[host: 'db01', db: @dataset].except(:adapter).merge(symbolize_keys: true))
    @spreadsheet = @session.spreadsheet_by_title('races_new')
  end

  def parse_races
    worksheet = @spreadsheet.worksheets[5]
    races     = worksheet.rows[4..472]
    title     = Race.new.attributes.keys[1..10]
    data      = races.map do |race|
      new_race = {}
      race.each_with_index do |item, idx|
        next if idx == 10

        new_race[title[idx]] = item
      end
      new_race
    end
    save_races(data)
  end

  def parse_candidates
    worksheet  = @spreadsheet.worksheets[7]
    candidates = worksheet.rows[4..-1]
    title      = Candidate.new.attributes.keys[1..48]
    data       = candidates.map do |candidate|
      new_candidate = {}
      candidate.each_with_index do |item, idx|
        if title[idx].match?(/year/)
          item = item[0..3].sub(',', '')
          item = increase_in_length(item)
        end
        if item.match?(/\d/) && item.match?(/,/) && title[idx].match?(/number_of_votes/)
          new_candidate[title[idx]] = item.sub(',', '').to_i
        else
          new_candidate[title[idx]] = item
        end
      end
      new_candidate
    end
    save_candidates(data)
  end

  def update_candidates_photo
    candidates_old = CandidateOld.all
    candidates     = Candidate.all
    candidates.each do |candidate|
      candidate_photo_aws = candidates_old.find { |i| i[:candidate_photo] == candidate[:candidate_photo] }[:candidate_photo_aws]
      next if candidate_photo_aws.nil? || !candidate[:candidate_photo_aws].nil?

      puts candidate_photo_aws.green
      candidate.update({candidate_photo_aws: candidate_photo_aws})
    end
  end

  private

  def increase_in_length(str)
    return str if str.empty? || str.size > 3

    str.chop!
    increase_in_length(str)
  end

  def save_races(data)
    Race.insert_all(data)
  end

  def save_candidates(data)
    Candidate.insert_all(data)
  end
end

# frozen_string_literal: true

require_relative '../lib/il_dupage__keeper'
require_relative '../lib/il_dupage__scraper'
require_relative '../lib/il_dupage__parser'

require_relative '../models/il_dupage__arrestees'
require_relative '../models/il_dupage__arrestee_ids'
require_relative '../models/il_dupage__arrestee_addresses'
require_relative '../models/il_dupage__arrestee_aliases'
require_relative '../models/il_dupage__arrests'
require_relative '../models/il_dupage__charges'
require_relative '../models/il_dupage__court_hearings'
require_relative '../models/il_dupage__bonds'
require_relative '../models/il_dupage__holding_facilities'
require_relative '../models/il_dupage__mugshots'

class IlDuPageManager < Hamster::Harvester

  FILE_NAME = 'il_dupage_json'

  def initialize
    super
    @keeper = IlDuPageKeeper.new
    @parser = IlDuPageParser.new
    @scraper = IlDuPageScraper.new
    @run_id = @keeper.run_id
  end

  def download
    send_to_slack message: "Project #0490 download started"
    @keeper.start_download
    puts '======================================== download started ========================================'
    @keeper.clear_store_folder
    data = @scraper.download
    return if data.nil?
    @keeper.save_file(data, FILE_NAME)
    # binding.pry
    @keeper.finish_download
    puts '======================================== download finished ========================================'
    send_to_slack message: "Project #0490 download finished"
  end

  def store
    send_to_slack message: "Project #0490 store started"
    @keeper.start_store
    puts '======================================== store started ========================================'
    data = @keeper.give_file(FILE_NAME)
    parsed = @parser.parse_json(data)
    # binding.pry
    @arrestee_md5 = @keeper.list_saved_md5(IlDuPageArrestee)
    store_inmates(parsed)
    update_all_deleted_status
    @keeper.finish
    puts '======================================== store finished ========================================'
    send_to_slack message: "Project #0490 store finished"
  end

  private

  def store_inmates(parsed)
    inmate_groups = parsed["InmateGroups"]
    return if inmate_groups.nil?
    inmate_groups.each do |group|
      group.each { |arrestee| store_inmate(arrestee) }
    end
  end

  def store_inmate(inmate_info)

    arrestee_db_id = store_info(inmate_info)
    store_mugshot(inmate_info, arrestee_db_id)
    store_id(inmate_info, arrestee_db_id)

    arrest_id = store_arrest(inmate_info, arrestee_db_id)
    store_charges_and_court_hearings(inmate_info, arrest_id)
    store_bonds(inmate_info, arrest_id)

  rescue StandardError => e
    puts e, e.full_message
    send_to_slack message: "Project #0490 store_inmate:\n#{e.inspect}"
  end

  def store_info(inmate_info)
    arrestee_info = @parser.parse_arrestee(inmate_info)
    if @arrestee_md5.include? arrestee_info[:md5_hash]
      arrestee_db = @keeper.update_touched_run_id(IlDuPageArrestee, arrestee_info[:md5_hash]).first
      return arrestee_db.id
    end

    @keeper.store(arrestee_info, IlDuPageArrestee)
    @keeper.last_id(IlDuPageArrestee)
  end

  def store_mugshot(inmate_info, arrestee_db_id)
    mugshot_url = inmate_info["ImageUrl"].include?("inmate-placeholder.png") ? nil : inmate_info["ImageUrl"]
    arrestee_mugshot =  @keeper.arrestee_mugshot(arrestee_db_id)
    if arrestee_mugshot && (arrestee_mugshot.original_link == mugshot_url)
      @keeper.update_touched_run_id(IlDuPageMugshot, arrestee_mugshot.md5_hash)
      return
    end
    mugshot_aws_url = nil
    unless mugshot_url.nil?
      photo_file = @scraper.get_page(mugshot_url)
      mugshot_aws_url = @keeper.save_to_aws(mugshot_url, photo_file)
    end
    mugshot = @parser.parse_mugshot(inmate_info, arrestee_db_id, mugshot_aws_url)
    @keeper.store(mugshot, IlDuPageMugshot)
  end

  def store_id(inmate_info, arrestee_db_id)
    arrestee_id = @parser.parse_arrestee_id(inmate_info, arrestee_db_id)
    return unless @keeper.update_touched_run_id(IlDuPageArresteeID, arrestee_id[:md5_hash]).empty?

    @keeper.store(arrestee_id, IlDuPageArresteeID)
  end

  def store_arrest(inmate_info, arrestee_db_id)
    arrest = @parser.parse_arrest(inmate_info, arrestee_db_id)

    arrest_db = @keeper.update_touched_run_id(IlDuPageArrest, arrest[:md5_hash]).first
    return arrest_db.id if arrest_db

    @keeper.store(arrest, IlDuPageArrest)
    @keeper.last_id(IlDuPageArrest)
  end

  def store_charges_and_court_hearings(inmate_info, arrest_id)
    charges = @parser.parse_charges(inmate_info, arrest_id)
    charges.each do |charge|
      court_room = charge.delete(:court_room)
      charge_db = @keeper.update_touched_run_id(IlDuPageCharge, charge[:md5_hash]).first
      if charge_db
        charge_db_id = charge_db.id
      else
        @keeper.store(charge, IlDuPageCharge)
        charge_db_id = @keeper.last_id(IlDuPageCharge)
      end
      court_hearing = @parser.parse_court_hearing(charge, court_room, charge_db_id)
      next unless @keeper.update_touched_run_id(IlDuPageCourtHearing, court_hearing[:md5_hash]).empty?

      @keeper.store(court_hearing, IlDuPageCourtHearing)
    end
  end

  def store_bonds(inmate_info, arrest_id)
    bonds = @parser.parse_bonds(inmate_info, arrest_id)
    bonds.each do |bond|
      next unless @keeper.update_touched_run_id(IlDuPageBond, bond[:md5_hash]).empty?
      @keeper.store(bond, IlDuPageBond)
    end
  end

  def update_all_deleted_status
    @keeper.update_deleted_status(IlDuPageArrestee)
    @keeper.update_deleted_status(IlDuPageMugshot)
    @keeper.update_deleted_status(IlDuPageArresteeID)
    @keeper.update_deleted_status(IlDuPageArrest)
    @keeper.update_deleted_status(IlDuPageCharge)
    @keeper.update_deleted_status(IlDuPageCourtHearing)
    @keeper.update_deleted_status(IlDuPageBond)
  end

  def send_to_slack(message:, channel: 'U031HSK8TGF')
    Hamster.report(message: message, to: channel)
  end

end

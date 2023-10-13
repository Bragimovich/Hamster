# frozen_string_literal: true
require_relative '../models/il_will__arrestees'
require_relative '../models/il_will__arrestee_aliases'
require_relative '../models/il_will__arrestee_addresses'
require_relative '../models/il_will__arrestee_ids'
require_relative '../models/il_will__mugshots'
require_relative '../models/il_will__arrests'
require_relative '../models/il_will__charges'
require_relative '../models/il_will__court_hearings'
require_relative '../models/il_will__bonds'
require_relative '../models/il_will__holding_facilities'
require_relative '../models/il_will_runs'
class ILWillKeeper < Hamster::Scraper
  def initialize(run = 1)
    @run_id = run
    @s3 = AwsS3.new(:hamster, :hamster)
  end
  def store_data(raw)
    @raw = raw
    @charge_data = []
    @touched_run_id = @run_id
    fill_arestees_table
    fill_aliases_table
    fill_addresses_table
    fill_arrestees_ids_table
    @raw[:mugshots].each do |mugshot|
    fill_mugshots_table(mugshot)
    end
    @raw[:booking_numbers].each do |booking|
      fill_arests_table(booking)
    booking[:charges].each do |charge|
      fill_charges_table(charge)
    end
    booking[:hearings].each do |hearing|
      fill_hearings_table(hearing)
    end
    booking[:bonds].each do |bond|
      fill_bonds_table(bond)
    end
      fill_facility_table(booking)
    end
  end
  def fill_arestees_table
    begin
      h = {}
      h[:full_name] = @raw[:full_name]
      h[:age] = @raw[:age]
      h[:sex] = @raw[:gender]
      h[:race] = @raw[:race]
      h[:height] = @raw[:height]
      h[:weight] = @raw[:weight]
      data = {full_name: h[:full_name], age: h[:age], race: h[:race], sex: h[:sex], height: h[:height], weight: h[:weight]}
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_arestee = IlWillArrestees.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_arestee
        hash = IlWillArrestees.flail { |key| [key, h[key]] }
        IlWillArrestees.store(hash)
      else
        existing_arestee.update(touched_run_id: @run_id)
      end
      @arestee_id = IlWillArrestees.find_by(md5_hash: md5_hash, deleted: false)[:id]
      IlWillArrestees.clear_active_connections!
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_aliases_table
    begin
      if  @raw[:aliases]
      h = {}
      h[:arrestee_id] = @arestee_id
      h[:full_name] = @raw[:aliases]
      data = {arrestee_id: h[:arrestee_id], full_name: h[:full_name]}
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_aliases = IlWillAliases.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_aliases
        hash = IlWillAliases.flail { |key| [key, h[key]] }
        IlWillAliases.store(hash)
      else
        existing_aliases.update(touched_run_id: @run_id)
      end
      IlWillAliases.clear_active_connections!
      end
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_addresses_table
    begin
      h = {}
      h[:arrestee_id] = @arestee_id
      h[:full_address] = @raw[:street_address].to_s + ', ' + @raw[:city_state_zip].to_s
      h[:street_address] = @raw[:street_address]
      h[:city] = @raw[:city]
      h[:state] = @raw[:state]
      h[:zip] = @raw[:zip]
      data = {arrestee_id: h[:arrestee_id], street_address: h[:street_address], city_state_zip: @raw[:city_state_zip]}
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      if h[:full_address] != ', '
      existing_address = IlWillArresteeAddresses.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_address
        hash = IlWillArresteeAddresses.flail { |key| [key, h[key]] }
        IlWillArresteeAddresses.store(hash)
      else
        existing_address.update(touched_run_id: @run_id)
      end
      IlWillArresteeAddresses.clear_active_connections!
      end
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_arrestees_ids_table
    begin
      h = {}
      h[:arrestee_id] = @arestee_id
      h[:number] = @raw[:arrestee_id]
      data = {arrestee_id: h[:arrestee_id], number: h[:number]}
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

        existing_id = IlWillArresteeIds.find_by(md5_hash: md5_hash, deleted: false)
        unless existing_id
          hash = IlWillArresteeIds.flail { |key| [key, h[key]] }
          IlWillArresteeIds.store(hash)
        else
          existing_id.update(touched_run_id: @run_id)
        end
      IlWillArresteeIds.clear_active_connections!
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_mugshots_table(mugshot)
    begin
      h = {}
      h[:arrestee_id] = @arestee_id
      aws_link = save_to_aws(mugshot[:original_link], @raw[:full_name])
      if aws_link
      h[:aws_link] = aws_link
      h[:original_link] = mugshot[:original_link]
      h[:notes] = mugshot[:notes]
      data = {arrestee_id: h[:arrestee_id], original_link: h[:original_link], notes: h[:notes]}
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_mugshot = IlWillMugshots.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_mugshot
        hash = IlWillMugshots.flail { |key| [key, h[key]] }
        IlWillMugshots.store(hash)
      else
        existing_mugshot.update(touched_run_id: @run_id)
      end
      IlWillMugshots.clear_active_connections!
      end
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_arests_table(raw)
    begin
      h = {}
      h[:arrestee_id] = @arestee_id
      h[:booking_date] = raw[:booking_date]
      h[:booking_agency] = raw[:booking_agency]
      h[:booking_agency_subtype] = raw[:booking_agency_subtype]
      h[:booking_number] = raw[:booking_number]
      h[:status] = raw[:status]
      data = {arrestee_id: h[:arrestee_id],
              booking_date: h[:booking_date],
              booking_agency: h[:booking_agency],
              booking_number: h[:booking_number],
              status: h[:status]
             }
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash

      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_arest = IlWillArrests.find_by(booking_number: raw[:booking_number], md5_hash: md5_hash, deleted: false)
      unless existing_arest
        hash = IlWillArrests.flail { |key| [key, h[key]] }
        IlWillArrests.store(hash)
      else
        existing_arest.update(touched_run_id: @run_id)
      end
      @arest_id = IlWillArrests.find_by(md5_hash: md5_hash, deleted: false)[:id]
      IlWillArrests.clear_active_connections!
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_charges_table(raw)
    begin
      if raw[:charge_number]
      h = {}
      h[:arrest_id] = @arest_id
      h[:number] = raw[:charge_number]
      h[:description] = raw[:charge_description]
      h[:offense_date] = Date.strptime(raw[:offense_date_time], '%m/%d/%Y %I:%M %p').to_s if raw[:offense_date_time]
      h[:offense_time] = raw[:offense_date_time]
      h[:crime_class] = raw[:crime_class]
      h[:attempt_or_commit] = raw[:attempt_or_commit]
      h[:docket_number] = raw[:docket_number]
      h[:sentence_date] = raw[:sentence_date]
      h[:sentence_length] = raw[:sentence_length]
      h[:arresting_agency] = raw[:arresting_agency]
      data = {arrest_id: h[:arrest_id],
              number: h[:number],
              description: h[:description],
              offense_date_time: raw[:offense_date_time],
              crime_class: raw[:crime_class],
              attempt_or_commit: h[:attempt_or_commit],
              docket_number: h[:docket_number],
              sentence_date: h[:sentence_date],
              sentence_length: h[:sentence_length],
              arresting_agency: h[:arresting_agency]
      }
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_charge = IlWillCharges.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_charge
        hash = IlWillCharges.flail { |key| [key, h[key]] }
        IlWillCharges.store(hash)
      else
        existing_charge.update(touched_run_id: @run_id)
      end
      @charge_id = IlWillCharges.find_by(md5_hash: md5_hash, deleted: false)[:id]
      @charge_data << [@charge_id, h[:number]]
      IlWillCharges.clear_active_connections!
      end
    rescue => e
      puts "#{e} | #{e.backtrace}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
    def fill_bonds_table(raw)
      begin
        if raw[:bond_number]
        h = {}
        h[:arrest_id] = @arest_id
        h[:bond_category] = 'Surety Bonds'
        h[:bond_number] = raw[:bond_number]
        h[:bond_type] = raw[:bond_type]
        h[:bond_amount] = raw[:bond_amount]

        data = {arrest_id: h[:arrest_id],
                bond_number: h[:bond_number],
                bond_type: h[:bond_type],
                bond_amount: h[:bond_amount]
        }
        md5_hash = MD5Hash.new(columns: data.keys)
        md5_hash.generate(data)
        md5_hash = md5_hash.hash
        h[:md5_hash] = md5_hash
        h[:data_source_url] = @raw[:data_source_url]
        h[:run_id] = @run_id
        h[:touched_run_id] = @run_id

        existing_bond = IlWillBonds.find_by(md5_hash: md5_hash, deleted: false)
        unless existing_bond
          hash = IlWillBonds.flail { |key| [key, h[key]] }
          IlWillBonds.store(hash)
        else
          existing_bond.update(touched_run_id: @run_id)
        end
        IlWillBonds.clear_active_connections!
        end
      rescue => e
        puts "#{e} | #{e.backtrace}"
        File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
          name.puts "#{e} | #{e.backtrace}"
        end
      end
    end
  def fill_hearings_table(raw)
    begin
      if raw[:charge_number]
      h = {}
      h[:charge_id] = @charge_data.select{|i| i[1] == raw[:charge_number]}[0][0]
      h[:court_date] =  Date.strptime(raw[:court_date_time], '%m/%d/%Y %I:%M %p').to_s if raw[:court_date_time] && raw[:court_date_time] != ''
      h[:court_time] = raw[:court_date_time]
      h[:court_room] = raw[:court_room]
      h[:type] = 'VIDEO' if raw[:court_room] && raw[:court_room].include?('VIDEO')

      data = {charge_id: h[:charge_id],
              court_date_time: raw[:court_date_time],
              court_room: h[:court_room],
              type: h[:type]
      }
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_hearing = IlWillCourtHearings.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_hearing
        hash = IlWillCourtHearings.flail { |key| [key, h[key]] }
        IlWillCourtHearings.store(hash)
      else
        existing_hearing.update(touched_run_id: @run_id)
      end
      IlWillCourtHearings.clear_active_connections!
      end
    rescue => e
      puts "#{e} | #{e.backtrace}|||For invalid date #{raw[:court_date_time]}"
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def fill_facility_table(raw)
    begin
      h = {}
      h[:arrest_id] = @arest_id
      h[:facility] = raw[:facility]
      h[:start_date] = raw[:booking_date]
      h[:actual_release_date] = raw[:actual_release_date]

      data = {arrest_id: h[:arrest_id],
              facility: h[:facility],
              start_date: h[:start_date],
              actual_release_date: h[:actual_release_date]
      }
      md5_hash = MD5Hash.new(columns: data.keys)
      md5_hash.generate(data)
      md5_hash = md5_hash.hash
      h[:md5_hash] = md5_hash
      h[:data_source_url] = @raw[:data_source_url]
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      existing_facility = IlWillHoldingFacilities.find_by(md5_hash: md5_hash, deleted: false)
      unless existing_facility
        hash = IlWillHoldingFacilities.flail { |key| [key, h[key]] }
        IlWillHoldingFacilities.store(hash)
      else
        existing_facility.update(touched_run_id: @run_id)
      end
      IlWillHoldingFacilities.clear_active_connections!
    rescue => e
      puts "#{e} | #{e.backtrace}"
        File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
  def check_deleted
    IlWillArrestees.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillAliases.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillArresteeAddresses.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillMugshots.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillArrests.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillCharges.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillBonds.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillCourtHearings.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillHoldingFacilities.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    IlWillCrimeRuns.all.to_a.last.update(status: 'finished')
  end
  def assign_new_run
    h = {}
    h[:status] = 'processing'
    hash = IlWillCrimeRuns.flail{|key| [key, h[key]]}
    IlWillCrimeRuns.store(hash)
    IlWillCrimeRuns.maximum(:id)
  end
  def save_to_aws(link, name)
    begin
    file_name = link.split('/').last.gsub('?type=Full', '')
    key = "crime_perps_mugshots/il/will/" + file_name + ".jpg"
    aws_link = "https://hamster-storage1.s3.amazonaws.com/#{key}"
    p aws_link
    exist_file = IlWillMugshots.find_by(aws_link: aws_link, deleted: false)
    unless exist_file
      cobble = Dasher.new(:using=>:cobble)
      cobble.get_file(link)
      foto = File.open("#{storehouse}store/#{file_name}", 'r')
      @s3.put_file(foto, key, metadata={full_name: name})
      File.delete("#{storehouse}store/#{file_name}") if File.exist?("#{storehouse}store/#{file_name}")
    end
    aws_link
    rescue => e
      File.open("#{storehouse}store/project_0488_log.txt", 'a') do |name|
        name.puts "#{e} | #{e.backtrace}"
      end
    end
  end
end


# frozen_string_literal: true

require_relative 'scraper_crime_data'
require_relative 'parser_crime_data'
require_relative 'keeper'
# require_relative 'aws_s3'

class ManagerCrimeData < Hamster::Harvester
  def initialize(**options)
    super
    @peon = Peon.new(storehouse)
    @data_source_url = 'https://www.mchenrysheriff.org/wp-content/uploads/pdf-uploads/InmateSearch_ByDate.pdf'

    @keeper = Keeper.new
    @md5_cash_maker = {
      arrestees: MD5Hash.new(columns: %i[full_name age sex mugshot deleted data_source_url]),
      arrestee_ids: MD5Hash.new(columns: %i[number type deleted data_source_url]),
      arrests: MD5Hash.new(columns: %i[booking_number arrestee_id deleted status arrest_date booking_date booking_agency booking_agency_type booking_agency_subtype data_source_url]),
      charges: MD5Hash.new(columns: %i[arrest_id disposition description deleted crime_class data_source_url]),
      bond: MD5Hash.new(columns: %i[arrest_id bond_category bond_number bond_type deleted bond_amount paid made_bond_release_date made_bond_release_time data_source_url]),
      court: MD5Hash.new(columns: %i[charge_id court_name court_room deleted data_source_url]),
      holding_activity: MD5Hash.new(columns: %i[arrest_id facility start_date deleted planned_release_date actual_release_date data_source_url]),
      mugshot: MD5Hash.new(columns: %i[arrestee_id aws_link original_link notes deleted data_source_url])
    }

    download if options[:scrape]
    parse_and_save if options[:parse]
    upload_images if options[:upload]
    upload_new_persons if options[:new_persons]
    upload_images_g_driwe if options[:g_drive]

    if options[:update]
      result = download
      parse_and_save if result
    end
  end

  def download
    scraper = ScraperCrimeData.new
    run_id = assign_new_run

    scraper.link_by
    time = DateTime.now.strftime('%s')
    path_to_save = "#{storehouse}#{run_id}"

    create_dir(path_to_save)

    File.open("#{path_to_save}/#{time}.pdf", 'wb') do |file|
      file.write(scraper.content)
    end

    # convert pdf to html
    str = "pdf2htmlEX --split-pages 1 #{path_to_save}/#{time}.pdf --dest-dir #{path_to_save} --page-filename file1.html"

    pid = Process.fork
    puts "current pid :#{pid}"
    if pid.nil? then
      exec(str)
    else
      puts "Sub Process ID:#{Process.wait(pid)}"
    end

    Hamster.report(to: 'dmitiry.suschinsky', message: "#McHenry - SCRAPE DONE")
    true
  rescue SystemExit, Interrupt, StandardError => e
    Hamster.report(to: 'dmitiry.suschinsky', message: "#McHenry - SCRAPE exception: #{e}!")
    puts e.backtrace.join("\n")
    false
  end

  def parse_and_save
    run = IlMchenryRuns.all.to_a.last
    @run_id = run && %w(processing error pause scraped).include?(run[:status]) ? run[:id] : (commands[:run_id] || raise(ValidateError, 'No active or scraped scrapings.'))

    filelist = []
    Dir["#{storehouse}#{@run_id}/*.html"].each do |path|
      filelist.push(path) if path.to_s.include?('file')
      # filelist.push(path) if path.to_s.include?('file12.html')
    end

    filelist.each_with_index do |path, index|
      file = read_file(path)
      document = Nokogiri::HTML.parse(file)
      @parser = ParserCrimeData.new(document)
      data_list = @parser.data_list

      next if data_list.instance_of?(NilClass)

      data_list.each do |person_objects|
        person_objects.each do |objects|
          next unless objects.instance_of?(Array)

          objects.each do |object|
            if object.instance_of?(IlMchenryArrestees)
              puts 'IlMchenryArrestees'
              break if object[:full_name].include?('Waiting')
              put_arrestee(object)
            elsif object.instance_of?(IlMchenryArresteeIds)
              puts 'IlMchenryArresteeIds'
              put_arrestee_ids(object)
            elsif object.instance_of?(IlMchenryArrests)
              puts 'IlMchenryArrests'
              put_arrests(object)
            elsif object.instance_of?(IlMchenryBonds)
              puts 'IlMchenryBonds'
              put_bond(object)
            elsif object.instance_of?(Array)
              object.each do |obj|
                if obj.instance_of?(IlMchenryCharges)
                  puts 'IlMchenryCharges'
                  work_with_charges(obj)
                elsif obj.instance_of?(IlMchenryCourtHearing)
                  puts 'IlMchenryCourtHearing'
                  put_court(obj)
                end
              end
            end
          end
        end
      end

      # break if index.zero?
    end
    finish_with_models(@run_id)
    Hamster.report(to: 'dmitiry.suschinsky', message: "#McHenry - Parse DONE files(#{filelist.size})")

  rescue SystemExit, Interrupt, StandardError => e
    puts '--------------------------------------'
    puts e
    puts e.backtrace.join("\n")
    Hamster.report(to: 'dmitiry.suschinsky', message: "#McHenry - PARSE exception: #{e}!")
  end

  def upload_new_persons
    puts 'upload_new_persons'
  end

  def upload_images_g_driwe
    puts 'upload_images_g_driwe'
  end

  def upload_images
    #TODO подключить АПИ гугл-диска
    run = IlMchenryRuns.all.to_a.last
    @run_id = run && %w(processing error pause scraped).include?(run[:status]) ? run[:id] : (commands[:run_id] || raise(ValidateError, 'No active or scraped scrapings.'))

    @aws_s3 = AwsS3.new(:hamster, :hamster)

    filelist = []
    Dir["#{storehouse}/#{@run_id}/img/*.jpg"].each do |path|
      filelist.push(path)
    end
    puts filelist.size

    arrestees = IlMchenryArrestees.where.not(full_name: nil).uniq
    puts arrestees.size

    arrestees.each do |person|
      filelist.each do |file|
        next unless file.include?(person[:full_name])
        puts person[:full_name]
        mugshot = {
          arrestee_id: person[:id],
          aws_link: "https://hamster-storage1.s3.amazonaws.com/crime_perps_mugshots/il/mchenry/#{person[:full_name]}.jpg",
          run_id: @run_id, touched_run_id: @run_id,
          data_source_url: person[:data_source_url]
        }
        puts @md5_cash_maker[:mugshot]
        mugshot[:md5_hash] = @md5_cash_maker[:mugshot].generate(mugshot)
        @keeper.save_mugshot(mugshot)
        break
      end
    end
  rescue StandardError => e
    puts "e.message: #{e.message}"
    puts e
    puts e.backtrace.join("\n")
  end

  private

  def assign_new_run
    h = {}
    h[:status] = 'processing'
    hash = IlMchenryRuns.flail{|key| [key, h[key]]}
    IlMchenryRuns.store(hash)
    IlMchenryRuns.maximum(:id)
  end

  def create_dir(dir)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
  end

  def read_file(dir)
    File.open(dir, &:read)
  rescue StandardError => e
    puts 'ERROR read file'
    puts "e.message: #{e.message}"
  end

  def put_arrestee(arrestee)
    person_arrestees = arrestee
    existed_arrestees = @keeper.existed_arrestees(person_arrestees[:full_name])

    person_arrestees[:run_id] = @run_id
    person_arrestees[:touched_run_id] = @run_id
    person_arrestees[:data_source_url] = @data_source_url

    hash = person_arrestees.as_json

    if existed_arrestees.nil?
      person_arrestees[:md5_hash] = @md5_cash_maker[:arrestees].generate(hash)
      @keeper.save_arrestees(person_arrestees.as_json)
      # person_arrestees.save
      @arrestee_id = @keeper.get_arrestees_id(person_arrestees[:full_name])
    else
      existed_arrestees.update(touched_run_id: @run_id, deleted: 0)
      @arrestee_id = existed_arrestees.id
    end
  end

  def put_arrestee_ids(arrestee_ids)
    existed_arrestee_ids = @keeper.existed_arrestee_ids(arrestee_ids[:number])

    arrestee_ids[:run_id] = @run_id
    arrestee_ids[:touched_run_id] = @run_id
    arrestee_ids[:arrestee_id] = @arrestee_id
    arrestee_ids[:date_from] = nil
    arrestee_ids[:data_source_url] = @data_source_url

    hash = arrestee_ids.as_json

    if existed_arrestee_ids.nil?
      arrestee_ids[:md5_hash] = @md5_cash_maker[:arrestee_ids].generate(hash)
      @keeper.save_arrestee_ids(arrestee_ids.as_json)
      # arrestee_ids.save
    else
      existed_arrestee_ids.update(touched_run_id: @run_id, deleted: 0)
    end
  end

  def put_arrests(arrest)
    arrest[:run_id] = @run_id
    arrest[:touched_run_id] = @run_id
    arrest[:arrestee_id] = @arrestee_id
    arrest[:arrest_date] = nil
    arrest[:data_source_url] = @data_source_url

    hash = arrest.as_json

    arrest_md5_hash = @md5_cash_maker[:arrests].generate(hash)
    arrest[:md5_hash] = arrest_md5_hash

    existed_row = @keeper.get_arrest_by_md5_hash(arrest_md5_hash)

    if existed_row.nil?
      @keeper.save_arrests(arrest.as_json)
      @arrest_id = @keeper.get_arrests_id(arrest[:md5_hash])
    else
      existed_row.update(touched_run_id: @run_id, deleted: 0)
      @arrest_id = existed_row.id
    end
  end

  def work_with_charges(charge)
    @charge_id = put_charge(@arrest_id, charge)
  end

  def put_charge(arrest_id, charge)
    charge_to_db = {
      arrest_id: arrest_id,
      description: charge[:description],
      data_source_url: @data_source_url,
      run_id: @run_id,
      touched_run_id: @run_id,
      crime_class: charge[:crime_class]
    }
    charges_md5_hash = @md5_cash_maker[:charges].generate(charge_to_db)
    charge_to_db[:md5_hash] = charges_md5_hash
    existed_charge = @keeper.get_charge(charge[:description], arrest_id)

    if existed_charge.nil?
      @keeper.keep_charge(charge_to_db)
      existed_charge = @keeper.get_charge(charge[:description], arrest_id)
    else
      existed_charge.update(touched_run_id: @run_id, deleted: 0)
    end
    existed_charge.id
  end

  def put_bond(bond)
    bond_to_db = {
      arrest_id: @arrest_id,
      # charge_id: @charge_id,
      data_source_url: @data_source_url,
      paid: 0,
      run_id: @run_id,
      touched_run_id: @run_id,
      made_bond_release_date: bond[:made_bond_release_date],
      made_bond_release_time: bond[:made_bond_release_time]
    }

    unless bond[:bond_amount].nil?
      if bond[:bond_category]&.include?('Total Bond')
        bond_to_db[:bond_amount] = bond[:bond_amount]
        bond_to_db[:bond_category] = bond[:bond_category]
      elsif bond[:bond_category]&.include?('No Bond')
        bond_to_db[:bond_amount] = nil
        bond_to_db[:bond_category] = nil
      end
    end

    if bond[:bond_category] == 'MADE BOND'
      bond_to_db[:paid] = 1
    end

    bond_md5_hash = @md5_cash_maker[:bond].generate(bond_to_db)
    bond_to_db[:md5_hash] = bond_md5_hash
    existed_bond = @keeper.get_bond_by_md5(bond_md5_hash)
    if existed_bond.nil?
      @keeper.keep_bond(bond_to_db)
    else
      existed_bond.update(touched_run_id: @run_id, deleted: 0)
    end

  rescue SystemExit, Interrupt, StandardError => e
    puts '--------------------------------------'
    puts e
    puts e.backtrace.join("\n")
  end

  def put_court(charge)
    court_room = !charge[:court_room].include?('n/a') ? charge[:court_room] : nil
    court_hearing = {
      charge_id: @charge_id,
      data_source_url: @data_source_url,
      run_id: @run_id,
      touched_run_id: @run_id,
      court_room: court_room,
      case_number: charge[:case_number]
    }

    unless charge[:court_date].nil?
      court_hearing[:court_date] = charge[:court_date]
      court_hearing[:court_time] = charge[:court_time]
    end

    ch_md5_hash = @md5_cash_maker[:court].generate(court_hearing)
    court_hearing[:md5_hash] = ch_md5_hash

    existed_court = @keeper.get_court(court_hearing[:court_date], court_hearing[:case_number], charge[:court_room])
    if existed_court.nil?
      @keeper.keep_court_hearing(court_hearing)
    else
      existed_court.update(touched_run_id: @run_id, deleted: 0)
    end

  end

  def fail_check
    files = peon.give_list
    return if files.empty?

    failed_at = files.sort.last.split('.').first.split('_')[-2]
    failed_at.first.to_i
  end

  def finish_with_models(run_id)
    IlMchenryArrestees.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryArresteeIds.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryArrests.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryCharges.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryBonds.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryCourtHearing.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryRuns.where(id: run_id).update(status: 'done')
  end

end

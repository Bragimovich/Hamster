# frozen_string_literal: true

require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'

class Manager < Hamster::Scraper
  def initialize(**options)
    super
    @peon = Peon.new(storehouse)
    scrape if options[:scrape]
    keep if options[:parse]
  end

  FILENAME = 'full_list'

  def scrape
    scraper = Scraper.new
    parser = Parser.new
    general_page_html = scraper.general_page

    return 0 if general_page_html.nil?

    today_string = Date.today.to_s.gsub('-','_')
    general_page_file_name = "#{FILENAME}_#{today_string}"
    @peon.put(content: general_page_html, file: general_page_file_name)
    persons = parser.general_page(general_page_html)
    p persons
    existed_person_files = @peon.give_list(subfolder:today_string).map! { |q| q.split('.')[0] }
    persons.each do |booking_id, person|
      next if existed_person_files.include?(booking_id)

      parson_page_html = scraper.person_page(person[:link])
      @peon.put(content: parson_page_html, file: booking_id)
    end
  end


  def keep

    today_string = Date.today.to_s.gsub('-','_')
    general_page_file_name = "#{FILENAME}_#{today_string}"
    general_page_html = @peon.give(file:general_page_file_name)
    return "FILE for #{today_string} is not exist" if general_page_html.nil?

    @parser = Parser.new()
    @keeper = Keeper.new()

    @md5_cash_maker = {
      :arrestees => MD5Hash.new(columns:[:full_name, :age, :sex, :mugshot, :data_source_url]),
      :addresses => MD5Hash.new(columns:[:arrestee_id, :full_address, :city, :state, :zip, :data_source_url]),
      :arrests => MD5Hash.new(columns:[:booking_number, :arrestee_id, :status, :arrest_date, :booking_date, :booking_agency, :booking_agency_type, :booking_agency_subtype, :data_source_url ]),
      :charges => MD5Hash.new(columns:[:arrest_id, :disposition, :description, :offense_date, :offense_time, :data_source_url]),
      :bond => MD5Hash.new(columns:[:arrest_id, :charge_id, :bond_category, :bond_number, :bond_type, :bond_amount, :paid, :made_bond_release_date, :made_bond_release_time, :data_source_url]),
      :court => MD5Hash.new(columns:[:charge_id, :court_name, :court_room, :data_source_url]),
      :holding_activity=> MD5Hash.new(columns:[:arrest_id, :facility, :start_date, :planned_release_date, :actual_release_date,  :data_source_url]),
      :mugshot=> MD5Hash.new(columns:[:arrestee_id, :aws_link, :original_link, :notes,  :data_source_url]),
    }

    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)


    run_id_model = RunId.new(IlKaneRuns)
    @run_id = run_id_model.last_id

    persons = @parser.general_page(general_page_html)
    person_files = @peon.give_list().map! { |filename| filename.split('.')[0] }
    persons.each do |booking_id, person_values|
      next if !booking_id.in?(person_files)
      p booking_id
      person_html = @peon.give(file:booking_id)
      charges = @parser.all_charges(booking_id, person_html)
      arrestee_id = put_arrestee(booking_id, person_html)
      arrest_id = put_arrest(arrestee_id, booking_id, person_html)
      put_address(arrestee_id, booking_id, person_html)

      work_with_charges(arrest_id, charges)
      put_holding_activities(arrest_id, booking_id, charges[0], person_html)
      @peon.move(file: booking_id, to:today_string)
      #full_person = parser.person_page(person_file,person_html)
    end

    if person_files.length>150
      run_id_model.finish
      @keeper.finish_with_models(@run_id)
    else
      puts "Not enough bookings. There are only #{person_files.length}. Download them by --scrape"
    end
    @peon.move(file: general_page_file_name, to:today_string)

  end


  private

  def put_arrestee(booking_id, html)
    person_arrestees = @parser.arrestees(booking_id, html)
    existed_arrestees = @keeper.existed_arrestees(person_arrestees[:id])
    arrestee_id =
      if existed_arrestees.nil?
        person_arrestees[:run_id] = @run_id
        person_arrestees[:touched_run_id]= @run_id

        pict_link = person_arrestees[:mugshot]
        person_arrestees.delete(:mugshot)


        person_md5_hash = @md5_cash_maker[:arrestees].generate(person_arrestees)
        person_arrestees[:md5_hash] = person_md5_hash
        @keeper.save_arrestees(person_arrestees)
        mugshot_link = @aws_s3.put_file(Base64.decode64(pict_link['data:image/jpg;base64,'.length .. -1]),
                                        "crime_perps_mugshots/il/kane/#{person_arrestees[:full_name]}_#{booking_id}.jpg",
                                        metadata={'name'=> person_arrestees[:full_name], 'booking_number'=> booking_id})

        mugshot = {
          arrestee_id: person_arrestees[:id],
          aws_link: mugshot_link,
          run_id: @run_id, touched_run_id: @run_id,
          data_source_url: person_arrestees[:data_source_url]
        }
        mugshot[:md5_hash] = @md5_cash_maker[:mugshot].generate(mugshot)
        @keeper.save_mugshot(mugshot)

        person_arrestees[:id]
      else
        existed_arrestees.update(touched_run_id:@run_id, deleted:0)
        existed_arrestees.id
      end


    arrestee_id
  end

  def put_arrest(arrestee_id, booking_id, html)
    arrest = @parser.arrest(booking_id, html)
    arrest[:run_id] = @run_id
    arrest[:touched_run_id]= @run_id
    arrest[:arrestee_id] = arrestee_id
    arrest_md5_hash = @md5_cash_maker[:arrests].generate(arrest)
    arrest[:md5_hash] = arrest_md5_hash

    existed_row = @keeper.get_arrest_by_md5_hash(arrest_md5_hash)

    arrest_id =
      if existed_row.nil?
        @keeper.save_arrests(arrest)
        @keeper.get_arrest(booking_id)
      else
        existed_row.update(touched_run_id:@run_id, deleted:0)
        existed_row.id
      end
    arrest_id

  end

  def put_address(arrestee_id, booking_id, html)
    address = @parser.address(booking_id, html)
    address[:run_id] = @run_id
    address[:touched_run_id]= @run_id
    address[:arrestee_id] = arrestee_id
    address_md5_hash = @md5_cash_maker[:addresses].generate(address)
    address[:md5_hash] = address_md5_hash

    existed_row = @keeper.get_address_by_md5_hash(address_md5_hash)

    if existed_row.nil?
        @keeper.save_address(address)
    else
        existed_row.update(touched_run_id:@run_id, deleted:0)
    end
  end

  def work_with_charges(arrest_id, charges)
    charges.each do |charge|
      if charge[:bond_category].nil?
        charge_id = put_charge(arrest_id, charge)
        put_bond(arrest_id,charge_id,charge)
        put_court(charge_id, charge)
      else
        put_bond(arrest_id,nil,charge)
      end

    end
  end

  def put_charge(arrest_id, charge)
    charge_to_db = {
      arrest_id: arrest_id,
      description: charge[:description],
      data_source_url: charge[:data_source_url],
      run_id: @run_id,
      touched_run_id: @run_id
    }
    charges_md5_hash = @md5_cash_maker[:charges].generate(charge_to_db)
    charge_to_db[:md5_hash] = charges_md5_hash
    existed_charge = @keeper.get_charge(charges_md5_hash)
    if existed_charge.nil?
      @keeper.keep_charge(charge_to_db)
      existed_charge = @keeper.get_charge(charges_md5_hash)
    else
      existed_charge.update(touched_run_id:@run_id, deleted:0)
    end
    existed_charge.id
  end

  def put_bond(arrest_id,charge_id,charge)
    bond_to_db = {
      arrest_id: arrest_id,
      charge_id: charge_id,
      data_source_url: charge[:data_source_url],
      paid: 0,
      run_id: @run_id,
      touched_run_id: @run_id
    }

    if !charge[:bond_amount].nil?

      if !charge[:bond_category].nil?
        bond_to_db[:bond_amount] = charge[:bond_amount]
        bond_to_db[:bond_category] = charge[:bond_category]
      elsif !['NO BOND'].include?(charge[:bond_amount])
        bond_to_db[:bond_amount] = charge[:bond_amount]
        bond_to_db[:bond_category] = 'Cash Bail'
      end
      if charge[:bond_amount]=='$0.00'
        bond_to_db[:paid]=1
      end

    else
      bond_to_db[:bond_amount] = nil
    end

    if !charge[:reason_release].nil? and charge[:reason_release]=='Bonded'
      bond_to_db[:paid] = 1
      date_time = charge[:actual_release_date]
      if !date_time.nil?
        bond_to_db[:made_bond_release_date] = Date.strptime(date_time,'%m/%d/%Y ')
        bond_to_db[:made_bond_release_time] = Time.parse(date_time.split(' ')[1..].join(' '))
      end
    end
    bond_md5_hash = @md5_cash_maker[:bond].generate(bond_to_db)
    bond_to_db[:md5_hash] = bond_md5_hash
    existed_bond = @keeper.get_bond_by_md5(bond_md5_hash)
    if existed_bond.nil?
      @keeper.keep_bond(bond_to_db)
    else
      existed_bond.update(touched_run_id:@run_id, deleted:0)
    end

  end

  def put_court(charge_id, charge)
    court_hearing = {
      charge_id: charge_id,
      data_source_url: charge[:data_source_url],
      run_id: @run_id,
      touched_run_id: @run_id
    }
    full_court_name = charge[:court_name]
    court_hearing[:court_name], court_hearing[:court_room] = full_court_name.split('Courtroom').map! { |q| q.strip  } if !full_court_name.nil?

    if !charge[:court_date].nil?
      court_hearing[:court_date] = Date.strptime(charge[:court_date],'%m/%d/%Y ')
      court_hearing[:court_time] = Time.parse(charge[:court_date].split(' ')[1..].join(' '))
    end

    ch_md5_hash = @md5_cash_maker[:court].generate(court_hearing)
    court_hearing[:md5_hash] = ch_md5_hash

    existed_court = @keeper.get_court_by_md5(ch_md5_hash)
    if existed_court.nil?
      @keeper.keep_court_hearing(court_hearing)
    else
      existed_court.update(touched_run_id:@run_id, deleted:0)
    end

  end

  def put_holding_activities(arrest_id, booking_id, charge, person_html)
    holding_activity = @parser.holding_activity(booking_id, person_html)
    holding_activity[:arrest_id] = arrest_id
    holding_activity[:run_id] = @run_id
    holding_activity[:touched_run_id] = @run_id
    if !charge.nil?
      holding_activity[:planned_release_date] = Date.strptime(charge[:planned_release_date],'%m/%d/%Y ') if !charge[:planned_release_date].nil?
      holding_activity[:actual_release_date] = Date.strptime(charge[:actual_release_date],'%m/%d/%Y ') if !charge[:actual_release_date].nil?
    end
    ha_md5_hash = @md5_cash_maker[:holding_activity].generate(holding_activity)
    holding_activity[:md5_hash] = ha_md5_hash

    existed_hf = @keeper.get_ha_by_md5(ha_md5_hash)
    if existed_hf.nil?
      @keeper.keep_holding_activity(holding_activity)
    else
      existed_hf.update(touched_run_id:@run_id, deleted:0)
    end
  end
end
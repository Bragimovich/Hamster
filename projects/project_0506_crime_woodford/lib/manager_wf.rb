# frozen_string_literal: true

class ManagerWF < Hamster::Scraper

  def initialize(**options)
    super
    @peon = Peon.new(storehouse)

    crime = options[:all].nil? ? 'current' : 'all'
    @first_letter = options[:letter]
    #@update = !options[:update].nil?

    scrape(crime) if options[:scrape]



    if options[:parse]
      run_id_model = RunId.new(IlWoodfordRuns)
      @run_id = run_id_model.last_id
      keep(crime)
      if crime!='all'
        @keeper.mark_deleted_arrests_released(@run_id)
        run_id_model.finish
      end
    end

  end

  def scrape(crime='current')
    subfolder = crime
    save_file = "save_file_#{crime}"
    statistic_file = storehouse + 'statistics'
    scraper = ScraperWF.new(crime)
    keeper = KeeperWf.new()
    numb_of_arrestes = 0
    if crime=='all' and "#{save_file}.gz".in? @peon.give_list()
      @peon.give(file:save_file)
    end

    letters =
      if crime=='current'
        ['']
      else
        ('A'..'Z')
      end

    letters.each do |letter|
      if !@first_letter.nil? and crime!='current'
        next if letter!=@first_letter
        @first_letter = nil
      end
      log(letter,'red')
      letter_empty = 0
      loop do
        numb_of_arrestes = scraper.number_of_arrestees(letter)
        break if numb_of_arrestes>0
        next if letter!=''
        letter_empty +=1
        p "E: #{letter_empty}"
        sleep(1)
      end
      log("For letter #{letter}: #{numb_of_arrestes} bookings")

      if crime=='all'
        subfolder = crime + '/' + letter
      end


      first_number = 0

      if crime=='all'
        saved_bookings = @peon.give_list(subfolder:subfolder).map { |booking| booking.split('.')[0] }
        bookings_on_page = ParserWF.all_arrestees(scraper.body, crime)
        booking_ids_on_page = bookings_on_page.map { |book| book[:booking_id]}
        saved_bookings += keeper.released_booking_ids(booking_ids_on_page-saved_bookings)
        bookings_on_page.each do |arr|
          break if !saved_bookings.include?(arr[:booking_id])
          first_number += 1
        end
      end

      File.open(statistic_file, "a") { |f| f.write "#{letter} - #{numb_of_arrestes}\n" }
      (first_number..numb_of_arrestes-1).each do |number|
        log("Booking ##{number}") if number%20==0
        html = scraper.person_page(number)
        booking_id = ParserWF.all_arrestees(html, crime)[number][:booking_id]
        @peon.put(content: html, file: booking_id, subfolder: subfolder)
        @peon.put(content: "#{letter}:#{number}", file: save_file+crime)
      end
    end
  end


  def keep(crime="current")
    log("Start keep #{crime} arrestees.")
    subfolder = crime

    @keeper = KeeperWf.new()

    @md5_cash_maker = {
      :arrestees => MD5Hash.new(columns:[:full_name, :age, :sex, :mugshot, :data_source_url]),
      :arrests => MD5Hash.new(columns:[:booking_number, :arrestee_id, :status, :arrest_date, :booking_date, :booking_agency, :booking_agency_type, :booking_agency_subtype, :data_source_url ]),
      :charges => MD5Hash.new(columns:[:arrest_id, :disposition, :description, :offense_date, :offense_time, :data_source_url]),
      :bond => MD5Hash.new(columns:[:arrest_id, :charge_id, :bond_category, :bond_number, :bond_type, :bond_amount, :paid, :made_bond_release_date, :made_bond_release_time, :data_source_url]),
      :court => MD5Hash.new(columns:[:charge_id, :court_name, :court_room, :court_date, :court_time, :data_source_url]),
      :holding_activity=> MD5Hash.new(columns:[:arrest_id, :facility, :start_date, :planned_release_date, :actual_release_date,  :data_source_url]),
      :mugshot=> MD5Hash.new(columns:[:arrestee_id, :aws_link, :original_link, :notes,  :data_source_url]),
    }

    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)

    letters =
      if crime=='current'
        ['']
      else
        ('A'..'Z')
      end
    letters.each do |letter|
      if crime=='all'
        subfolder = crime + '/' + letter
      end

      arrestees_files = @peon.give_list(subfolder:subfolder)

      arrestees_booking_ids = arrestees_files.map{|arr| arr.split('.')[0]}
      released_booking_ids = @keeper.released_booking_ids(arrestees_booking_ids)

      arrestees_list = []
      arrestees_files.each_with_index do |file, index|
        log("Arrestee: #{index}") if index%20==0
        arrestee_hash = {booking_id: file.split('.')[0]}
        next if released_booking_ids.include?(arrestee_hash[:booking_id])

        html = @peon.give(file: file, subfolder:subfolder)

        arrestees_list = ParserWF.all_arrestees(html, crime) if arrestees_list.empty?

        arrestees_list.each_with_index do |arreste, arr_index|
          if arrestee_hash[:booking_id]==arreste[:booking_id]
            arrestee_hash = arreste
            arrestees_list.delete_at(arr_index)
          end
        end

        parser = ParserWF.new(html, arrestee_hash)
        arrestee_id = put_arrestees(parser)
        arrest_id = put_arrest(parser, arrestee_id)
        charge_ids = put_charge(parser, arrest_id)
        put_bond(parser, arrest_id, charge_ids)
        put_court(parser, arrest_id)
        @peon.move(file: file, from:subfolder, to:subfolder) if crime!='all'
      end
    end

  end


  private

  def put_arrestees(parser)
    person_arrestees = parser.general_info

    existed_arrestees = @keeper.existed_arrestees(person_arrestees[:full_name])

    person_arrestees[:run_id] = @run_id
    person_arrestees[:touched_run_id]= @run_id


    if existed_arrestees.nil?
        pict_link = person_arrestees[:mugshot_base64]
        person_arrestees.delete(:mugshot_base64)

        person_arrestees[:md5_hash] = @md5_cash_maker[:arrestees].generate(person_arrestees)
        @keeper.save_arrestees(person_arrestees)
        existed_arrestees = @keeper.existed_arrestees(person_arrestees[:full_name])

        if pict_link!="img/user.png"
          metadata={}
          metadata['name'] = person_arrestees[:full_name] unless person_arrestees[:full_name].nil?
          metadata['booking_number'] = parser.booking_id unless parser.booking_id.nil?

          mugshot_link = @aws_s3.put_file(Base64.decode64(pict_link['data:image/jpg;base64,'.length .. -1]),
                                        "crime_perps_mugshots/il/woodford/#{person_arrestees[:full_name]}_#{parser.booking_id}.jpg",
                                          metadata = metadata
                                        )
          mugshot = {
            arrestee_id: existed_arrestees.id,
            aws_link: mugshot_link,
            run_id: @run_id, touched_run_id: @run_id,
            data_source_url: person_arrestees[:data_source_url]
          }
          mugshot[:md5_hash] = @md5_cash_maker[:mugshot].generate(mugshot)
          @keeper.save_mugshot(mugshot)
        end

    else
        existed_arrestees.update(touched_run_id:@run_id, deleted:0)
    end

    existed_arrestees.id
  end


  def put_arrest(parser, arrestee_id)
    arrest = parser.arrests_info
    arrest[:run_id] = @run_id
    arrest[:touched_run_id]= @run_id
    arrest[:arrestee_id] = arrestee_id
    arrest_md5_hash = @md5_cash_maker[:arrests].generate(arrest)
    arrest[:md5_hash] = arrest_md5_hash

    existed_row = @keeper.get_arrest_by_md5_hash(arrest_md5_hash)

    arrest_id =
      if existed_row.nil?
        @keeper.save_arrests(arrest)
        @keeper.get_arrest(parser.booking_id)
      else
        existed_row.update(touched_run_id:@run_id, deleted:0)
        existed_row.id
      end
    @keeper.mark_deleted_arrests(@run_id, arrestee_id)
    arrest_id
  end

  def put_charge(parser, arrest_id)
    charges = parser.charges_info
    charges_id = []
    charges.each do |charge_to_db|
      charge_to_db.merge!({
        arrest_id: arrest_id,
        run_id: @run_id,
        touched_run_id: @run_id
      })
      charges_md5_hash = @md5_cash_maker[:charges].generate(charge_to_db)
      charge_to_db[:md5_hash] = charges_md5_hash
      existed_charge = @keeper.get_charge(charges_md5_hash)
      if existed_charge.nil?
        @keeper.keep_charge(charge_to_db)
        existed_charge = @keeper.get_charge(charges_md5_hash)
      else
        existed_charge.update(touched_run_id:@run_id, deleted:0)
      end
      charges_id.push(existed_charge.id)
    end
    @keeper.mark_deleted_charges(@run_id, arrest_id)
    charges_id
  end

  def put_bond(parser, arrest_id, charges_id)
    bonds = parser.bonds_info

    bonds.each_with_index do |bond_to_db, index|
      bond_to_db.merge!({
        arrest_id: arrest_id,
        charge_id: charges_id[index],
        run_id: @run_id,
        touched_run_id: @run_id
      })
      bond_md5_hash = @md5_cash_maker[:bond].generate(bond_to_db)
      bond_to_db[:md5_hash] = bond_md5_hash
      existed_charge = @keeper.get_bond_by_md5(bond_md5_hash)
      if existed_charge.nil?
        @keeper.keep_bond(bond_to_db)
      else
        existed_charge.update(touched_run_id:@run_id, deleted:0)
      end
    end
    @keeper.mark_deleted_bonds(@run_id, arrest_id)
  end

  def put_court(parser, arrest_id)
    courts = parser.court_info

    courts.each do |court|
      court.merge!({
                     arrest_id: arrest_id,
                          run_id: @run_id,
                          touched_run_id: @run_id
                        })
      court_md5_hash = @md5_cash_maker[:court].generate(court)
      court[:md5_hash] = court_md5_hash
      existed_charge = @keeper.get_court_by_md5(court_md5_hash)
      if existed_charge.nil?
        @keeper.keep_court_hearing(court)
      else
        existed_charge.update(touched_run_id:@run_id, deleted:0)
      end
    end

    @keeper.mark_deleted_courts(@run_id, arrest_id)
  end
end



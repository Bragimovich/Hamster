require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper
  def download
    scraper = Scraper.new
    (1..).each do |page|
      links = scraper.links(page)
      break if links.blank?
      page_save(links)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    message_send('Download finish!')
  end

  def page_save(links)
    scraper = Scraper.new
    links.each do |link|
      name = Digest::MD5.hexdigest(link).to_s
      name += '.html'
      page = scraper.page(link)
      content = "<p><b>data_source_url: </b><a class='original_link' href='#{link}'>#{link}</a></p>" + page.body
      peon.put(file: name, content: content)
      puts "File save! #{name}".green
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
  end

  def store
    parser = Parser.new
    keeper = Keeper.new
    index = 1
    keeper.add_run('store start!')
    run_id = keeper.get_run
    files = peon.give_list
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      page = peon.give(file: file)
      inmate = parser.page_parse(page)
      next if inmate.blank?
      arrestee = {
        full_name: inmate[:full_name],
        age: inmate[:age],
        race: inmate[:race],
        sex: inmate[:sex],
        height: inmate[:height],
        weight: inmate[:weight],
        data_source_url: inmate[:data_source_url]
      }
      keeper.add_arrestee(arrestee, run_id, index)
      arrestee_id = keeper.get_arrestee_id(inmate[:data_source_url])
      next if arrestee_id.blank?
      id = {
        arrestee_id: arrestee_id,
        number: inmate[:number],
        type: "subject number",
        data_source_url: inmate[:data_source_url]
      }
      keeper.add_id(id, run_id)
      address = {
        arrestee_id: arrestee_id,
        full_address: inmate[:full_address],
        street_address: inmate[:street_address],
        city: inmate[:city],
        state: inmate[:state],
        zip: inmate[:zip],
        data_source_url: inmate[:data_source_url]
      }
      keeper.add_address(address, run_id)
      aliases = inmate[:aliases]
      aliases.each do |name|
        aliase = {
          arrestee_id: arrestee_id,
          full_name: name,
          data_source_url: inmate[:data_source_url]
        }
        keeper.add_alias(aliase, run_id)
      end
      mugshots = inmate[:mugshots]
      mugshots.each do |item|
        aws_link = keeper.get_aws_link(item[:mugshot_original])
        aws_link = keeper.save_to_aws(item[:mugshot_original]&.strip) if aws_link.blank?
        mugshot = {
          arrestee_id: arrestee_id,
          aws_link: aws_link,
          original_link: item[:mugshot_original],
          notes: item[:mugshot_notes]
        }
        keeper.add_mugshot(mugshot, run_id)
      end
      bookings = inmate[:bookings]
      bookings.each do |booking|
        arrest = {
          arrestee_id: arrestee_id,
          booking_date: booking[:booking_date],
          booking_agency: booking[:booking_agency],
          booking_number: booking[:booking_number],
          data_source_url: inmate[:data_source_url]
        }
        keeper.add_arrest(arrest, run_id)
        arrest_id = keeper.get_arrest_id(booking[:booking_number], arrestee_id)
        facility = {
          arrest_id: arrest_id,
          facility: booking[:facility],
          start_date: booking[:booking_date],
          planned_release_date: booking[:planned_release_date],
          actual_release_date: booking[:actual_release_date],
          data_source_url: inmate[:data_source_url]
        }
        keeper.add_facility(facility, run_id)
        total_bond = {
          arrest_id: arrest_id,
          charge_id: nil,
          bond_category: 'Total Bond',
          bond_number: nil,
          bond_type: nil,
          bond_amount: booking[:total_bond],
          paid: 0,
          data_source_url: inmate[:data_source_url]
        }
        keeper.add_total_bond(total_bond, run_id)
        total_bail = {
          arrest_id: arrest_id,
          charge_id: nil,
          bond_category: 'Total Bail',
          bond_number: nil,
          bond_type: nil,
          bond_amount: booking[:total_bail],
          paid: 0,
          data_source_url: inmate[:data_source_url]
        }
        keeper.add_total_bond(total_bail, run_id)
        booking_charges = booking[:booking_charges]
        booking_charges.each do |item|
          charge = {
            arrest_id: arrest_id,
            number: item[:charge_number],
            disposition: item[:disposition],
            disposition_date: item[:disposition_date],
            description: item[:description],
            offense_date: item[:offense_date],
            crime_class: item[:crime_class],
            attempt_or_commit: item[:attempt_or_commit],
            docket_number: item[:docker_number],
            bond_number: item[:bond_number],
            data_source_url: inmate[:data_source_url]
          }
          offense_time = item[:offense_time]
          keeper.add_charge(charge, offense_time, run_id)
        end
        booking_court_info = booking[:booking_court_info]
        booking_court_info.each do |item|
          charges = item[:charges]
          charges.each do |charge|
            charge_id = keeper.get_charge_id(charge, arrest_id)
            hearing = {
              charge_id: charge_id,
              court_name: item[:court],
              court_date: item[:court_date],
              court_room: item[:court_room],
              data_source_url: inmate[:data_source_url]
            }
            court_time = item[:court_time]
            keeper.add_hearing(hearing, court_time, run_id)
          end
        end
        booking_bonds = booking[:booking_bonds]
        booking_bonds.each do |item|
          charge_id = keeper.get_charge_id_bond(item[:bond_number],arrest_id)
          bond = {
            arrest_id: arrest_id,
            charge_id: charge_id,
            bond_category: 'Surety Bonds',
            bond_number: item[:bond_number],
            bond_type: item[:bond_type],
            bond_amount: item[:bond_amount],
            data_source_url: inmate[:data_source_url]
          }
          keeper.add_bond(bond, run_id)
        end
      end
      peon.move(file: file)
      index += 1
    rescue => e
      if e.message.include?('These is an issue connecting') || e.message.include?("Can't connect to MySQL") || e.message.include?("MySQL client is not connected") || e.message.include?("Lost connection to MySQL server") || e.message.include?("Lock wait timeout exceeded")
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        puts message
        sleep(600)
        retry
      else
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        puts message
        message_send(message)
      end
    end
    peon.throw_trash
    keeper.missing_pages(run_id)
    keeper.update_run('store finish!')
    message_send('Store finish!')
  end
end
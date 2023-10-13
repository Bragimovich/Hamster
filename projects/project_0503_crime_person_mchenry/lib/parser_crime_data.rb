# frozen_string_literal: true
class ParserCrimeData < Hamster::Parser
  def initialize(doc)
    @html = doc
  end

  def data_list
    divs = []
    content_arr = []
    jca = ''

    elements = @html.css('div.c')
    elements.each_with_index do |node, index|
      jca = node.content if node.content.include? 'JCA#: '
      content_arr << node.content.strip unless node.content.include? 'JCA#:'

      next_value = elements[index + 1].nil? ? 0 : elements[index + 1].content.strip

      if next_value != 0 && next_value.include?('JCA#:')
        hash = { jca => content_arr }
        content_arr = []
        divs << hash
      elsif next_value.instance_of?(Integer) && next_value.zero?
        hash = { jca => content_arr }
        content_arr = []
        divs << hash
      end
    end

    data_list = {}
    divs.each_with_index do |div, index|
      div.each do |key, value|
        puts "key: #{key}"
        number = key.match /(\d+)/
        charge_ = false
        counter = 0

        charges = []
        charge = nil
        court_hearings = []
        court_hearing = nil

        arrestees = IlMchenryArrestees.new
        arrestee_ids = IlMchenryArresteeIds.new
        arrests = IlMchenryArrests.new
        bonds = IlMchenryBonds.new

        arrestee_ids[:number] = number
        arrestee_ids[:type] = 'JCA number'

        value.each_with_index do |val, index|
          val.gsub!(/\s{2,}/, ' ')

          if index.zero?
            # puts "---Name: #{val}"
            arrestees[:full_name] = val

          elsif !charge_ && val.include?('Date Confined')
            status = value[index + 1].gsub(/\s{2,}/, ' ')
            if status.include?('CURRENTLY CONFINED')
              arrests[:status] = status
            elsif status.include?('RECENTLY RELEASED ON')
              # puts "STATUS: #{status}"
              arrests[:status] = status.match(/\w+ \w+/)[0]
              bonds[:made_bond_release_date] = Date.strptime(status.match(%r{\d+/\d+/\d+})[0], '%m/%d/%Y')
              bonds[:made_bond_release_time] = Time.parse(status.match(/@ \d+:\d+/)[0])
              bonds[:bond_category] = 'MADE BOND' if status.include?('MADE BOND')
            end

          elsif !charge_ && val.include?('Bond') && !val.include?('MADE BOND')
            puts "---Bond: #{val}"
            bonds[:bond_category] = val.include?('No Bond') ? val : 'Total Bond'
            bonds[:bond_amount] = val.match(/\d+,\d{1,}|\d+\d{1,}/)[0].gsub(',','').to_i if val.include?('Bond Is Set At')

          elsif !charge_ && value[index + 1] && !value[index + 1].gsub(/\s{2,}/, ' ').include?('Date Confined') && 
                val.scan(%r{\d+/\d+/\d+}).first && !val.include?('Last Updated on') && !val.include?('RECENTLY RELEASED')
            arrestees[:birthdate] = Date.strptime(val, '%m/%d/%Y')

          elsif val.include?('Status') || val.include?('Charges') || val.include?('Class') || val.include?('Case #') ||
                val.include?('Next Court Date') || val.include?('Court Room') || val.include?('Date of Birth')
            next

          elsif val.include?('Sentenced Release Date')
            charge_ = true
            counter = 1
            charge = IlMchenryCharges.new
            court_hearing = IlMchenryCourtHearing.new

          elsif charge_ && counter == 1
            # puts "---Status: #{val}"
            counter += 1

          elsif charge_ && counter == 2
            # puts "---Charges: #{val}"
            counter += 1
            charge[:description] = val

          elsif charge_ && counter == 3 && val.length == 1
            # puts "---Class: #{val}"
            counter += 1
            charge[:crime_class] = val

          elsif charge_ && counter == 4
            # puts "---Case #: #{val}"
            counter += 1
            court_hearing[:case_number] = val

          elsif charge_ && counter == 5
            # puts "---Next Court Date #: #{val}"
            counter += 1
            puts val
            court_hearing[:court_date] = Date.strptime(val, '%m/%d/%Y') unless val && val.include?('**not applicable**')
            court_hearing[:court_time] = Time.parse(val.match(/@ \d+:\d+/)[0]) unless val && val.include?('**not applicable**')

          elsif charge_ && counter == 6
            # puts "---Court Room #: #{val}"
            counter += 1
            court_hearing[:court_room] = val

          elsif charge_ && counter == 7 && value[index + 1].gsub(/\s{2,}/, ' ') && value[index + 1].gsub(/\s{2,}/, ' ').scan(%r{\d+/\d+/\d+ @ \d+:\d+\w+}).first
            # puts "---Sentenced Release Date: #{val}"
            counter = 0
            charge_ = false
            charge[:disposition_date] = Date.strptime(val, '%m/%d/%Y') unless val.include?('**not applicable**')

            charges << charge
            court_hearings << court_hearing

          elsif charge_ && counter == 7 && value[index + 1].gsub(/\s{2,}/, ' ') && value[index + 1].gsub(/\s{2,}/, ' ').scan(%r{\d+/\d+/\d+ @ \d+:\d+\w+}).first.nil?
            # puts "---Sentenced Release Date: #{val}"
            counter = 1
            charge[:disposition_date] = Date.strptime(val, '%m/%d/%Y') unless val.include?('**not applicable**')

            charges << charge
            court_hearings << court_hearing

            charge = IlMchenryCharges.new
            court_hearing = IlMchenryCourtHearing.new

          elsif value[index + 1]&.gsub(/\s{2,}/, ' ')&.include?('Date Confined') && val.scan(%r{\d+/\d+/\d+ @ \d+:\d+\w+}).first
            # puts "---Date Confined: #{Date.strptime(val, '%m/%d/%Y')}"
            date = Date.strptime(val, '%m/%d/%Y')
            arrestee_ids[:date_from] = date
            arrests[:arrest_date] = date
            arrests[:booking_date] = date
            arrests[:booking_number] = "#{date.year}#{date.month}#{date.day}-#{number}"

          elsif value[index + 1]&.gsub(/\s{2,}/, ' ')&.include?('Age')
            # puts "---Age: #{val}"
            arrestees[:age] = val
            arrestees[:age_as_of_date] = val
          else
            # puts 'You gave me -- I have no idea what to do with that.'
          end
        end
        # puts "bond_amount: #{bonds[:bond_amount]}"
        # puts "bond_category: #{bonds[:bond_category]}"

        data_list[index] = [arrestees, arrestee_ids, arrests, bonds, charges, court_hearings]
      end

      #TODO delete break
      # break if index.zero?
    end

    data_list

  rescue SystemExit, Interrupt, StandardError => e
    puts '--------------------------------------'
    puts e
    puts e.backtrace.join("\n")
  end

end

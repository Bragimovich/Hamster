# frozen_string_literal: true

class ParserWF < Hamster::Parser

  def initialize(html, booking_info={})
    @doc = Nokogiri::HTML(html)
    @booking_info = booking_info || {}
  end


  def self.all_arrestees(html, crime ='current')
    doc = Nokogiri::HTML(html)
    arrestess=[]

    tag =
      if crime=='current'
        '#inmateList'
      else
        '#lstPastInmate'
      end

    doc.css(tag).css('li').each do |arrestee|
      arrestess.push({
                       booking_id:arrestee['id'],
                       first_name:arrestee['fname'],
                       last_name:arrestee['lname'],
                     })
    end
    arrestess
  end


  def booking_id
    @booking_info[:booking_id]
  end


  GENERAL_REPLACE = {
    "lblSex"=>:sex,
    "lblDOB"=>:birthdate,
    "lblHeight"=>:height,
    "lblWeight"=>:weight,
    "lblRace"=>:race,
    "lblHair"=>:color_hair,
    "lblEye"=>:color_eye,
    "lblSkin"=>:skin,
    "lblBuild"=>:build,
    "lblNationality"=>:nationality,
  }

  def general_info
    body = @doc.css('div.user-info-box')
    arrestee = {}

    arrestee[:full_name] = body.css('p#pUserName')[0].content.strip
    if !arrestee[:full_name].include?(@booking_info[:last_name])
      @booking_info={}
    end

    arrestee[:first_name] =@booking_info[:first_name]
    arrestee[:last_name] =@booking_info[:last_name]

    arrestee[:mugshot_base64] = @doc.css('img#imgInmate')[0]['src']
    GENERAL_REPLACE.each do |label, column_name|
      value = body.css("p##{label}")[0].content.strip
      arrestee[column_name] = value if value!=''
    end
    arrestee[:birthdate] = Date.strptime(arrestee[:birthdate], '%m-%d-%Y')
    arrestee[:sex] = arrestee[:sex][0]
    arrestee
  end

  ARRESTS_REPLACE = {
    'Book Date'=>:booking_date,
    'Release Date'=>:release_date,
    'Arrest Agency'=>:booking_agency,
    #'Farm-Out Loc'=>:farm_out_loc,
  }

  ARRESTS_PLACE = ['Building', 'Pod', 'Cell', 'Bed']

  def arrests_info
    body = @doc.css('div#divInc')
    arrest = {
      booking_number: @booking_info[:booking_id]
    }
    body.css('tr').each do |tr|
      label = tr.css('td')[0].content.strip
      value = tr.css('td')[1].content.strip
      if ARRESTS_REPLACE.include?(label)
        if value!=''
          arrest[ARRESTS_REPLACE[label]] =
            if ['Book Date','Release Date'].include?(label)
              Date.strptime(value, '%m/%d/%Y')
            else
              value
            end
        end

      elsif ARRESTS_PLACE.include?(label)
        next if value!=''
        arrest[:booking_place] = '' if arrest[:booking_place].nil?
        arrest[:booking_place] += "#{label}:#{value};"
      end

    end
    arrest
  end


  def bonds_info
    body = @doc.css('table#tblBonds')

    bonds = []
    body.css('tbody').css('tr').each do |tr|
      td = tr.css('td')
      bonds.push({
                   #agency: td[0].content,
                   bond_type: td[1].content,
                   bond_amount: td[2].content,
                   bond_category: 'Surety Bond'
                 })
      bonds[-1][:paid]=
        if td[3].content.strip=='OPEN'
          0
        else
          1
        end
    end
    bonds
  end

  def charges_info
    body = @doc.css('table#tblCharges')
    charges = []
    body.css('tbody').css('tr').each do |tr|
      tds = tr.css('td')
      charges.push({
                     number: tds[0].content,
                     description: tds[1].content,
                     #type: tds[2].content,
                     disposition: tds[3].content,
                     docket_number: tds[4].content,
                     #otn: tds[5].content,
                     offense_date: tds[6].content,
                   }
      )
    end
    charges
  end

  def court_info
    body = @doc.css('div#divCourt').css('table')
    courts = []
    body.css('tr').each do |tr|
      tds = tr.css('td')
      next if tds[0].nil?
      court_time = tds[1].content
      courts.push({
                    court_name: tds[0].content.strip,
                    court_date: nil,
                    court_time: nil,
                    court_room: tds[2].content.strip,
                    type: tds[3].content.strip,
                   }
      )
      if !court_time.nil?
        court_times = court_time.split(' ')
        courts[-1][:court_date] = Date.strptime(court_times[0].strip, '%m/%d/%Y')
        courts[-1][:court_time] = court_time[1].strip if court_time.length>0
      end

    end
    courts
  end

end

# frozen_string_literal: true

require_relative '../models/models'

class Keeper
  def initialize
    @run_object = RunId.new(CaliforniaRuns)
    @run_id = @run_object.run_id
    @states = CaliforniaState.all.map(&:attributes)
    @cities = CaliforniaCity.all.map(&:attributes)
  end

  def save(data)
    @data = data
    arrestees_id = save_arrestee
    save_aliases(arrestees_id)
    save_mugshot(arrestees_id)
    save_offenses(arrestees_id)
    save_risk_assessments(arrestees_id)
    save_marks(arrestees_id)
    save_addresses(arrestees_id)
  end

  def finish
    @run_object.finish
  end

  private

  attr_reader :data

  def save_addresses(arrestees_id)
    hash = {
      full_address: "#{data['StreetAddress']} #{data['StreetName']}, #{data['City']}, #{data['ZIP']} County: #{data['County']}",
      city: data['City'],
      zip: data['ZIP'],
      state: data['State']
    }
    hash[:coordinate] = { lat: data['Latitude'], lon: data['Longitude']}
    address_id = save_address(hash)
    CaliforniaArresteeAdress.find_or_create_by(arrestees_id: arrestees_id, addresses_id: address_id)

    data['AddAddresses']&.each do |address|
      hash = {
        full_address: "#{address['StreetNumber']} #{address['StreetName']}, #{address['City']}, #{address['ZIP']} County: #{address['County']}",
        city: address['City'],
        zip: address['ZIP'],
        state: address['State'],
      }
      hash[:coordinate] = { lat: address['Lat'], lon: address['Lon']}
      address_id = save_address(hash)
      CaliforniaArresteeAdress.find_or_create_by(arrestees_id: arrestees_id, addresses_id: address_id)
    end
  end

  def save_address(hash)
    address = {}
    address[:full_address] = hash[:full_address]
    states_id = save_state(hash[:state])
    address[:states_id] = states_id
    address[:cities_id] = save_city(hash[:city], states_id)
    address[:zips_id] = save_zip(hash[:zip])
    address[:coordinates_id] = save_coordinate(hash[:coordinate])
    digest_update(CaliforniaAddress, address).id
  end

  def save_state(state)
    result = @states.find { |h| h['name'] == state }
    if result.nil?
      res = CaliforniaState.create(name: state)
      @states.push(res.attributes)
      res.id
    else
      result['id']
    end
  end

  def save_city(city, states_id)
    result = @cities.find { |h| h['name'] == city }
    if result.nil?
      res = CaliforniaCity.create(name: city, states_id: states_id)
      @cities.push(res.attributes)
      res.id
    else
      result['id']
    end
  end

  def save_zip(zip)
    CaliforniaZip.find_or_create_by(code: zip).id
  end

  def save_coordinate(hash)
    CaliforniaCoordinate.find_or_create_by(hash).id
  end

  def save_arrestee
    dob = Date.strptime(data['DOB'],'%m/%d/%Y')
    fullName = "#{data['LastName']}, #{data['FirstName']} #{data['MiddleName']}"
    arrestee = {
      full_name: fullName,
      first_name: data['FirstName'],
      middle_name: data['MiddleName'],
      last_name: data['LastName'],
      suffix: data['Suffix'],
      birthdate: dob,
      age: age(dob),
      race: data['Sex'],
      sex: data['Race'],
      height: data['Height'],
      weight: data['Weight'],
      eye_color: data['EyeColor'],
      hair_color: data['HairColor'],
    }
    digest_update(CaliforniaArrestee, arrestee).id
  end

  def save_aliases(arrestees_id)
    data['AKA']&.each do |aka|
      fullName = "#{aka['LastName']}, #{aka['FirstName']} #{aka['MiddleName']}"
      aka = {
        arrestees_id: arrestees_id,
        alias_full_name: fullName,
        alias_first_name: aka['FirstName'],
        alias_middle_name: aka['MiddleName'],
        alias_last_name: aka['LastName'],
        alias_suffix: aka['Suffix']
      }
      digest_update(CaliforniaArresteeAlias, aka)
    end
  end

  def save_mugshot(arrestees_id)
    aws_link = save_to_aws(data['mugshot_link'], data['FCN'])
    mugshot = {
      arrestees_id: arrestees_id,
      aws_link: aws_link,
      original_link: data['mugshot_link']
    }
    digest_update(CaliforniaMugshot, mugshot)
  end
  
  def save_to_aws(link, id)
    aws_s3 = AwsS3.new(:hamster, :hamster)
    key = "sex_offenders_mugshots/california/#{id}.jpg"
    aws_link = aws_s3.put_file(data['mugshot'], key, metadata={ url: link })
  end

  def save_offenses(arrestees_id)
    data['Offenses']&.each do |offense|
      offense = {
        arrestees_id: arrestees_id,
        offense_code: offense['Code'],
        last_conviction: offense['YearConvicted'],
        description: offense['Description'],
        last_release: offense['YearRelease']
      }
      digest_update(CaliforniaOffense, offense)
    end
  end

  def save_risk_assessments(arrestees_id)
    data['RA']&.each do |risk|
      risk = {
        arrestees_id: arrestees_id,
        score: risk['Score'],
        tool: risk['Tool'],
        year: risk['AssessDate']
      }
      digest_update(CaliforniaRiskAssessment, risk)
    end
  end

  def save_marks(arrestees_id)
    data['SMT']&.each do |mark|
      mark = {
        arrestees_id: arrestees_id,
        marks: mark['Mark']
      }
      digest_update(CaliforniaMark, mark)
    end
  end

  def md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.to_s)
  end

  def age(dob)
    now = Date.today
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def digest_update(object, hash)
    md5 = md5_hash(hash)
    digest = object.find_by(md5_hash: md5, deleted: false)
    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, md5_hash: md5})
      object.create(hash)
    else
      digest.update(touched_run_id: @run_id)
      digest
    end
  end
end

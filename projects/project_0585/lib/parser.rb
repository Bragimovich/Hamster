class Parser < Hamster::Parser
  def parse_json(json, data_source_url)
    @data_source_url = data_source_url
    @obituary_id = json[:obituary_details]['id'] || json[:obituary_details]['obituaryId']
    {
      tributearchive_hash: get_tribute_hash(json[:obituary_details]),
      setting_hash:        get_setting_hash(json[:obituary_details]),
      ceo_setting_hash:    get_ceo_setting_hash(json[:obituary_details]),
      funeral_home_hash:   get_funeral_home_hash(json[:obituary_details]),
      memorial_hash:       get_memorial_hash(json[:obituary_details])
    }
  end

  def get_json_from_details_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    encoded_string = parsed_page.at_xpath("//script[@id='my-app-id-state']").text
    decoded_string = unescape_html(encoded_string)
    json_data = JSON.parse(decoded_string)
    json_data.map{|k, v| v['body']}
  end

  private

  def unescape_html(text)
    unescaped_text = {
      '&a;' => '&',
      '&q;' => '"',
      '&s;' => '\'',
      '&l;' => '<',
      '&g;' => '>'
    }
    text.gsub(/&[^;]+;/) { |s| unescaped_text[s] }
  end
  
  def get_tribute_hash(json)
    birth_date = if json['birthDate'].present? && json['birthDate'].is_a?(String)
      Date.strptime(json['birthDate'], '%m/%d/%Y')
    elsif json['birthDate'].is_a?(Integer)
      Time.at(json['birthDate'])
    end    
    death_date = if json['deathDate'].present? && json['deathDate'].is_a?(String)
      Date.strptime(json['deathDate'], '%m/%d/%Y')
    elsif json['deathDate'].is_a?(Integer)
      Time.at(json['deathDate'])
    end
    description = json['description'].force_encoding('UTF-8') rescue nil
    description = description.presence ? description&.gsub(/<\/?[^>]*>/, "") : nil
    middle_name = json['middleName'].presence
    forests     = json['forests'].presence
    known_us    = json['knownUs'].force_encoding('UTF-8') rescue nil
    known_us    = known_us.presence
    data = {
      obituary_id: json['id'] || json['obituaryId'],
      obituary_description: description,
      full_name: json['fullName'].presence,
      city: json['city'].presence,
      state: json['state'].presence,
      birth_date: birth_date,
      death_date: death_date,
      funeral_home_name: json.dig('funeralHome','name') || json['funeralHomeName'],
      funeral_location_name: json.dig('funeralHome','location') || json['funeralLocationName'],
      hide_birth_date: json['hideBirthDate'].presence,
      hide_death_date: json['hideDeathDate'].presence,
      is_published: json['isPublished'].presence,
      image_url: json['imageUrl'].presence,
      thumbnail_url: json['thumbnailUrl'],
      tree_quantity: json['treeQuantity'].presence,
      forests: json['forests'].presence,
      first_name: json['firstName'].presence,
      last_name: json['lastName'].presence,
      middle_name: middle_name,
      known_us: known_us,
      gender: json['gender'].presence,
      domain_id: json['domainId'].presence,
      obituary_was_removed: json['obituaryWasRemoved'].presence,
      data_source_url: @data_source_url,
      show_captcha: json['show_captcha'].presence,
      public_key: json['public_key'].presence
    }
    data.merge!(md5_hash: create_md5_hash(data))
    transform_data(data)
  end

  def get_memorial_hash(json)
    memorial_data = []
    keys = %w[additionalInfo address phone name websiteAddress]
    memorial_hash = json.dig('memorialContributions')
    if memorial_hash
      memorial_hash.each do |hash|
        data = Hash[keys.map{|k| [k, hash[k]]}]
        data[:memorial_ids] = hash['id']
        data.merge!(obituary_id: @obituary_id, data_source_url: @data_source_url)
        data.merge!(md5_hash: create_md5_hash(data))
        memorial_data << transform_data(data)
      end
    end
    memorial_data
  end

  def get_ceo_setting_hash(json)
    keys = %w[imageUrl ogImageWidh ogImageHeight ogUrl description googlePlusAccountUrl]
    hash = json.dig('ceoSettings') || {}
    data = Hash[keys.map{|k| [k, hash[k]]}]
    description = json['description']&.force_encoding('UTF-8') rescue nil
    description = description&.strip&.empty? ? nil : description
    data['description'] = description
    og_image_width = data['ogImageWidh'].to_i.zero? ? nil : data['ogImageWidh'].to_i
    og_image_height = data['ogImageHeight'].to_i.zero? ? nil : data['ogImageHeight'].to_i
    data['ogImageWidh'] = og_image_width
    data['ogImageHeight'] = og_image_height
    data.merge!(obituary_id: @obituary_id, data_source_url: @data_source_url)
    data.merge!(md5_hash: create_md5_hash(data))
    transform_data(data)
  end

  def get_setting_hash(json)
    keys = %w[showStore showTributeFund tributeFundExpired crowdfundingExternalLink showStoreForPastEvent storeUrl useCustomStoreUrl disableTreeProduct privatizeGuestBook topBannerUrl isPlantTreeActive treeStoreLink hideTributeWall linkToObituaryWall hasPendingPosts hideReadMoreButton roundObituaryPhotos isDvdPurchaseEnabled]
    hash = json.dig('settings') || {}
    data = Hash[keys.map{|k| [k, hash[k]]}]
    data['storeUrl']      = data['storeUrl'].presence
    data['topBannerUrl']  = data['topBannerUrl'].presence
    data['treeStoreLink'] = data['treeStoreLink'].presence
    data.merge!(obituary_id: @obituary_id, data_source_url: @data_source_url)
    data.merge!(md5_hash: create_md5_hash(data))
    transform_data(data)
  end

  def get_funeral_home_hash(json)
    keys = %w[name url logoUrl]
    hash = json.dig('funeralHome') || {}
    data = Hash[keys.map{|k| [k, hash[k]]}]
    data.merge!(obituary_id: @obituary_id, data_source_url: @data_source_url)
    data.merge!(md5_hash: create_md5_hash(data))
    transform_data(data)
  end

  def transform_data(hash)
    HashWithIndifferentAccess.new(hash.transform_keys{|k| k.to_s.snake_case})
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end

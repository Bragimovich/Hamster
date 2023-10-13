# frozen_string_literal: true

require_relative '../models/us_weather_pictures'
require_relative '../models/us_weather_codes_pictures'

class PhotoUpdate
  def initialize
    aws_keys = Storage.new.aws_credentials_us_weather
    client = Aws::S3::Client.new(
      region: 'us-east-1',
      credentials: Aws::Credentials.new((aws_keys['access_key_id']).to_s, (aws_keys['secret_access_key']).to_s)
    )
    response = client.list_objects(bucket: 'loki-files', prefix: 'photo/weather/pictures/')
    @url = response.contents.map {|x| "https://loki-files.s3.amazonaws.com/" +  x.key }
    chech_aws
    check_table
  end

  def chech_aws
    @url[1..-1].each do |url|
      pictures = UsWeatherPictures.find_by(link: url)
      if pictures.nil?
        record = UsWeatherPictures.store(link: url)
        code_id = url.split('__').last.split('.').first.split('_')
        code_id.each do |id|
          UsWeatherCodesPictures.store(code_id: id, picture_id: record.id )
        end
      end
    end
  end

  def check_table
    UsWeatherPictures.select(:id, :link).pluck(:id, :link).each do |value|
      unless  @url[1..-1].include?(value[1])
        UsWeatherCodesPictures.where(picture_id: value[0]).delete_all
        UsWeatherPictures.find_by(id: value[0]).destroy
      end
    end
  end
end

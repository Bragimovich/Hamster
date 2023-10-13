# frozen_string_literal: true

class StoreLake < Hamster::Scraper
  def initialize
    super
    @aws_s3 = AwsS3.new(:hamster, :hamster)
  end

  def store_to_aws(hash, download_callback=nil)
    url_photo = hash[:photo]
    data_photo, name_file = download_callback.call(url_photo) unless download_callback.nil?
    metadata = {
      booking_number: hash[:booking],
      full_name: hash[:name],
    }
    @aws_s3.put_file(data_photo, "crime_perps_mugshots/il/lake/"+name_file, metadata)
  end

end
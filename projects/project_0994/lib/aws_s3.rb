class AwsS3_OLD
  def initialize
    s3 = get_aws_s3_client
    @bucket = s3.bucket('court-cases-activities')
  end

  COURTS = [1, 2, 12, 35, 38, 42, 48,49] #8 (edit url)

  def get_aws_s3_client
    aws_court_cases_activities = Storage.new.aws_credentials
    Aws.config.update(
      access_key_id: (aws_court_cases_activities['access_key_id']).to_s,
      secret_access_key: (aws_court_cases_activities['secret_access_key']).to_s,
      region: 'us-east-1'
    )
    Aws::S3::Resource.new(region: 'us-east-1')
  end

  def post_file_to_s3(body, metadata)
    random_key = SecureRandom.uuid
    key = "#{metadata[:court_id]}_#{metadata[:case_id]}_#{random_key}"

    @bucket.put_object(
      acl: 'public-read',
      key: key,
      body: body,
      metadata: metadata
    )

    [key, "https://court-cases-activities.s3.amazonaws.com/#{key}"]
  end

  def get_files_from_s3(courts=COURTS)
    courts.each do |court|
      p court
      @bucket.objects({:prefix=>"#{court.to_s}_"}).each do |object|
        puts "#{object.key} => #{object.etag}"
      end
    end
  end

  def save_file_to_local(key)
    large_object = @bucket.object(key)
    large_object.download_file("#{key}.pdf")
  end

  def delete_specific_files(court_id, case_id)
    keys_hash = @bucket.objects({:prefix=>"#{court_id.to_s}_#{case_id}_"}).map { |obj| {key:obj.key} }
    @bucket.delete_objects({delete:{objects:keys_hash}}) if !keys_hash.empty?
  end

  def delete_objects(court_id)
    keys_hash = @bucket.objects({:prefix=>"#{court_id}_"}).map { |obj| {key:obj.key} }
    @bucket.delete_objects({delete:{objects:keys_hash}}) if !keys_hash.empty?
  end

end


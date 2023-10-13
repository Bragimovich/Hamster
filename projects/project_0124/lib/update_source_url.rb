class UpdateSourceUrl
  def initialize(options)

    @links = Illinois_prod.where(data_source_url: nil, deleted: 0).pluck(:id, :uuid)
    if options[:single].nil?
      part  = @links.size / options[:instances] + 1
      @links = @links[(options[:instance] * part)...((options[:instance] + 1) * part)]
    end
  end
  
  def update
    @links.each do |record|
      Illinois_prod.find_by(id: record[0]).update(data_source_url: "https://www.iardc.org/Lawyer/PrintableDetails/#{record[1]}")
    end
  end
end

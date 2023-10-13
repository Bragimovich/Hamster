

PROJECTS = {
  54=>{path:'project_54/southern_district_ohio_court', court_id:36, court_name:'District Court for the Southern District of Ohio'},
  58=>{path:'project_58', court_id:25, court_name:'District Court for the Eastern District of New York'}, #/docket_reports_run_10
  48=>{path:'project48', court_id:51, court_name:'Michigan Eastern District Court'}, #/docket_reports_run_1
}


class PacerFiles < Hamster::Scraper

  def initialize(project)
    super

    @aws_s3 =AwsS3.new()
    open(project)


  end

  def open(project)
    p project
    time_start = Time.new()
    q=0
    begin
      project_number = project.to_i

      peon = Peon.new(storehouse)
      pathes = []
      if project_number==54
        pathes = [PROJECTS[project.to_i][:path]]
      elsif project_number.in?([48,58])
        project_path = PROJECTS[project.to_i][:path]
        full_path = storehouse + 'store/' + project_path
        p full_path
        pathes = []
        Dir.entries(full_path).select {|entry| pathes.push(project_path+'/'+entry) if entry.match('docket_reports_run_') }
      end

      court_id = PROJECTS[project.to_i][:court_id]


      pathes.each do |path|
        p path
        file_list = peon.give_list(subfolder: path)

        file_list.each do |filename|
          p filename
          next if !filename.match('.gz')
          q+=1

          html_file = peon.give(file: filename, subfolder: path)
          the_case = read_html(html_file)

          next if the_case.nil?

          path_to_file = storehouse + 'store/' + path + '/' + filename.split('.')[0]

          ready_html = delete_unnecessery_html(html_file)

          File.open(path_to_file+'.html', 'w') { |file| file.write(ready_html) }

          make_pdf_summary(path_to_file)

          key_name = "us_report_#{court_id}_#{the_case.keys[0]}_#{filename.split('.')[0]}.pdf"
          url_summary = put_to_aws(path_to_file, key_name)
          File.delete(path_to_file+'.pdf')

          CaseReportPacer.insert({
                                        court_id: court_id,
                                        court_name: PROJECTS[project.to_i][:court_name],
                                        case_id: the_case.keys[0],
                                        case_name: the_case.values[0][:case_name],
                                        pdf_summary: url_summary,
                                        top5_matches_summary: the_case.values[0][:top5words].to_s
                                      })

        end
      end

    # rescue => e
    #   p e

    ensure
      time_end = Time.new()
      divide = time_end-time_start
      p q,divide
      File.open('logs/us_case_report_pacer', 'a') { |fp| fp.write("Downloaded cases:#{q}|Time(sec):#{divide}\n") }
    end



  end

  def read_html(html)
    doc = Nokogiri::HTML(html)

    heading = doc.css('h3')[0]
    return if doc.nil? || heading.nil?
    #return if heading.content.match('CRIMINAL')

    case_id = heading.content.split('DOCKET FOR CASE #: ')[-1].split(' ')[0]
    case_name = doc.content.split('Case title: ')[-1].split("\n")[0]
    case_name = nil if case_name.match('CM/ECF')
    {case_id=> {
      case_name: case_name,
      top5words: how_many_words(doc.content).sort_by { |keyword, count| count }.last(5).reverse
      }}


  end

  def make_pdf_summary(path_to_file)
    system("wkhtmltopdf #{path_to_file}.html #{path_to_file}.pdf")
  end

  def delete_unnecessery_html(html)
    doc = Nokogiri::HTML(html)
    doc.to_s.split('U.S. District Court')[-1].split('PACER Service Center')[0]

  end


  def how_many_words(text)
    words = {}


    KEYWORDS.each do |keyword|
      next if keyword.in?(words)
      count = text.scan(keyword).size
      words[keyword] = count if count>0
    end

    words

  end

  def put_to_aws(path_to_file, keyname)
    File.open(path_to_file+'.pdf', 'rb') do |file|
      @aws_s3.put_file(file, keyname, metadata={})
    end
  end


  def delete_all
    @aws_s3.delete_files("us_report_")
  end


end
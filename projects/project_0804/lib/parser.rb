class Parser < Hamster::Parser
  def parse_csv(csv, year_file)
    year   = year_file.split('-').join(' - ').split('.')[0]
    for_db = []
    names  = csv.split(/\n/)
    names.each_with_index do |info, i|
      db               = {}
      elements         = info.squish.split(/\"/) #есть неровности и лишние пустоты в массиве
      db[:name]        = elements[1].gsub(',', ', ').squish
      pay_phrase       = ('$' + (elements.last.split('$').last)).gsub(',', '.')
      base_pay         = pay_phrase.split('.').map {|pay| pay.squish }
      if base_pay.size == 2
        db[:base_pay]  = base_pay.join('')
      elsif base_pay.size == 3
        db[:base_pay]  = base_pay[0] + base_pay[1] + '.' + base_pay[2]
      end
      db[:idx]         = i
      db[:salary_data] = year
      db[:primary_job_title]           = elements.last.split('$').first.tr(',.', '').squish
      if elements.last.split('$').last == elements.last.split('$').first
        db[:base_pay]          = 'upl'
        primary_job_title      = db[:primary_job_title].delete(db[:base_pay].match(/upl$/).to_s)
        db[:primary_job_title] = primary_job_title
      end
      for_db << db
    end
    for_db.each do |info|
      md5             = MD5Hash.new(columns: info.keys)
      info[:md5_hash] = md5.generate(info)
    end
    for_db
  end

  def parse_pdf(pdf, year)
    for_db_pdf = []
    pdf_pages  = PDF::Reader.new(open(pdf)).pages
    pdf_pages[0..-1].each do|page|
      info = page.text.split(/\n/)
      info.each_with_index do |employee, i|
        if !employee.match(/\$/).nil?
          db                     = {}
          db[:idx]               = i
          info                   = employee.split('    ').delete_if(&:blank?).map {|column_info| column_info.squish}
          db[:name]              = info[0].gsub(',', ', ').squish
          db[:primary_job_title] = info[1]
          base_pay               = info[2].split('$').last.gsub(',', '.').split('.')
          if base_pay.size == 2
            db[:base_pay] = '$' + base_pay.join('')
          elsif base_pay.size == 3
            db[:base_pay] = '$' + base_pay[0] + base_pay[1] + '.' + base_pay[2]
          end
          db[:salary_data] = year.split('.')[0].split('-').join(' - ')
          db[:base_pay].nil? ? next : for_db_pdf << db
        else
          next
        end
      rescue
        next
      end
    end
    for_db_pdf.each do |info|
      md5 = MD5Hash.new(columns: info.keys)
      info[:md5_hash] = md5.generate(info)
    end
  end
end

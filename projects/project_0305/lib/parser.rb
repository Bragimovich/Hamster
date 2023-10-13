class Parser < Hamster::Parser
  def fetch_page(main_page)
    Nokogiri::HTML(main_page.force_encoding('utf-8'))
  end

  def year_response(response)
    response.css('div.items [post_id="751"]')
  end

  def fetch_pdf_links(response)
    pdf_links = []
    response.each do |year|
      if year.text.squish == Date.today.year.to_s
        year.next_element.css('a').each do |link|
          pdf_links << link['href']
        end
      end
    end
    pdf_links
  end

  def data_row(lines, index)
    (lines[index] + lines[index + 1]).tr('^a-zA-Z0-9()%:,.', ' ').strip.split.join(' ')
  end

  def proportion_of_death_emergency_deparatment(lines, index)
    drow = data_row(lines, index)
    drow.split.select { |e| e.include? '%' }[0].gsub('%', '').to_f / 100
  end

  def proportion_of_outpatient_provider_visits(lines, index)
    drow = data_row(lines, index)
    drow.split.select { |e| e.include? '%' }[0].gsub('%', '').gsub('was', '').to_f / 100
  end

  def num_of_influenza_cases(row, lines, index)
    num_influenza_a_h3n2, num_influenza_a_h1n1, num_influenza_a_unknown_subtype, num_influenza_b = 0
    num_influenza_total, pct_tested_positive = 0
    drow = data_row(lines, index)
    unless drow.include? 'influenza B'
      drow = (lines[index]+lines[index+1]+lines[index+2]).tr('^a-zA-Z0-9()%:,.',' ').strip.split.join(" ")
    end
    num_influenza_total = drow.split('(')[0].gsub('•', '').strip.to_i
    if num_influenza_total.zero?
      num_influenza_total = NumbersInWords.in_numbers(drow.split('(')[0].gsub('•', '').strip)
    end
    pct_tested_positive = drow.split('(')[1].split(')').first.gsub('%', '').strip.to_f / 100
    drow = drow.split(':')[-1].split(',')
    drow.each do |val|
      if val.include? 'influenza A H3N2'
        num_influenza_a_h3n2 = val[0..val.index('influenza A H3N2') - 1].gsub('and', '').strip.to_i
      elsif val.include? 'influenza A H1N1'
        num_influenza_a_h1n1 = val[0..val.index('influenza A H1N1') - 1].gsub('and', '').strip.to_i
      elsif val.include? 'subtype'
        num_influenza_a_unknown_subtype = val[0..val.index('subtype') - 1].gsub('and', '').strip.to_i
      elsif (val.include? 'influenza B') || (val.include? 'influenza') || (val.include? 'in fluenza')
        num_influenza_b = val[0..val.index('in') - 1].gsub('and', '').strip.to_i
      end
    end
    [num_influenza_a_h3n2, num_influenza_a_h1n1, num_influenza_a_unknown_subtype, num_influenza_b, num_influenza_total, pct_tested_positive]
  end

  def num_flu_associated_icu(row, lines, index)
    drow = (lines[index]).tr('^a-zA-Z0-9()%:,.', ' ').strip.split.join(' ')
    num_flu_associated_icu = drow.gsub('•', '').strip.split(' ')[0].strip.to_i
    if num_flu_associated_icu.zero?
      num_flu_associated_icu = NumbersInWords.in_numbers(drow.gsub('•', '').gsub('influenza', '').strip.split(' ')[0].strip)
    end
    num_flu_associated_icu
  end

  def num_death_since(row, lines, index)
    num_pediatric_deaths_since_week35, num_clusters_il_schools_since_week35, num_outbreaks_in_long_term_care_since_week35 = 0
    drow = data_row(lines, index).split(',')[1..]
    drow.each do |val|
      if val.include? 'pediatric deaths'
        num_pediatric_deaths_since_week35 = val.strip.split(' ')[0].to_i
      elsif (val.include? 'clusters') || (val.include? 'cluster')
        num_clusters_il_schools_since_week35 = val.strip.split(' ')[0].to_i
      elsif (val.include? 'outbreaks') || (val.include? 'out')
        num_outbreaks_in_long_term_care_since_week35 = val.gsub('and', '').strip.split(' ')[0].to_i
      end
    end
    [num_pediatric_deaths_since_week35, num_clusters_il_schools_since_week35, num_outbreaks_in_long_term_care_since_week35]
  end

  def fetch_week(pdf)
    pdf.split('week')[-1].gsub('-', '').gsub('/', '').gsub('.pdf', '')
  end

  def parse_data(lines, pdf, run_id)
    data_hash = {}
    puts "Reading data from -> #{pdf}"
    rweek = fetch_week(pdf)
    
    lines.each_with_index do |row, index|
      if row.include? 'emergency department'
        data_hash[:proportion_of_emergency_deparatment_visits] = proportion_of_death_emergency_deparatment(lines, index)
      elsif (row.include? 'outpatient provider') || (row.include? 'ofoutpatient provider')
        data_hash[:proportion_of_outpatient_provider_visits] = proportion_of_outpatient_provider_visits(lines, index)
      elsif row.include? 'deaths associated'
        data_hash[:proportion_of_deaths_associated_with_flu] = proportion_of_death_emergency_deparatment(lines, index)
      elsif (row.include? 'laboratory specimens') || (row.include? 'laboratoryspecimens')
        data_hash[:num_influenza_a_h3n2] = num_of_influenza_cases(row, lines, index)[0]
        data_hash[:num_influenza_a_h1n1] = num_of_influenza_cases(row, lines, index)[1]
        data_hash[:num_influenza_a_unknown_subtype] = num_of_influenza_cases(row, lines, index)[2]
        data_hash[:num_influenza_b] = num_of_influenza_cases(row, lines, index)[3]
        data_hash[:num_influenza_total] = num_of_influenza_cases(row, lines, index)[4]
        data_hash[:pct_tested_positive] = num_of_influenza_cases(row, lines, index)[5]
      elsif row.include? '(ICU)'
        data_hash[:num_flu_associated_icu] = num_flu_associated_icu(row, lines, index)
      elsif row.include? 'Since'
        data_hash[:num_pediatric_deaths_since_week35] = num_death_since(row, lines, index)[0]
        data_hash[:num_clusters_il_schools_since_week35] = num_death_since(row, lines, index)[1]
        data_hash[:num_outbreaks_in_long_term_care_since_week35] = num_death_since(row, lines, index)[2]
        data_hash[:scrape_dev_name] = 'Adeel'
        data_hash[:scrape_frequency] = 'Weekly'
        data_hash[:link] = pdf
        data_hash[:week] = rweek
        data_hash[:year] = Date.today.year
        data_hash[:run_id] = run_id
        data_hash[:data_source_url] = 'https://cookcountypublichealth.org/epidemiology-data-reports/communicable-disease-data-reports/'
      end
    end
    data_hash
  end
end


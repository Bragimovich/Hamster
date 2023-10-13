class Parser <  Hamster::Parser
  DOMAIN = 'https://www.oig.dol.gov/'

  def get_inner_links(outer_page)
    outer_page = noko_response(outer_page)
    outer_page.css('div#fragment-23 li').map{|e| DOMAIN + e.css("a").attr('href').value.split.join("%20").gsub("’", "%E2%80%99").gsub("½", "%C2%BD")}.reject{|e| e.include? ".php" or e.include? ".htm" or e.include? "http://www." or !e.include? ".pdf"}
  end

  def links_data(outer_page,link,run_id,path, db_states)
      title, date            = get_title_date(outer_page, link)
      state, teaser, article = parser(path, title)
      state = fix_state(db_states, state)
      data_hash = {
        title: title,
        date: date,
        teaser: teaser,
        article: article,
        link: link,
        state: state,
        run_id: run_id
      }
      data_hash
  end

  private

  def fix_state(db_states, state)
    return state if state.nil?
    unless state.scan(/[,.;:]/).empty?
      character = state.scan(/[,.;:]/).first
      state = ((db_states & state.split(character)).empty?) ? nil : (db_states & state.split(character)).first
    end
    state
  end

  def noko_response(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def exception(e)
    Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end

  def get_title_date(outer_page, link)
      outer_page = noko_response(outer_page)
      html  = outer_page.css('div#fragment-23 li a').select{|e| e.attr("href").split.join("%20").gsub("’", "%E2%80%99").gsub("½", "%C2%BD") == link.gsub("#{DOMAIN}", "") }
      title = html.first.text.split("(", 2).first.strip
    begin
      date  = html.first.text.split("(", 2).last.split.last.gsub(")", "").gsub("20121", "2021")
      date  = Date.strptime(date, "%m/%d/%Y")
      [title, date]
    rescue Exception => e
      exception(e)
    end
  end

  def parser(file_path, title)
    begin
      reader = PDF::Reader.new(open(file_path))
      state, teaser, article = text_extractor(reader, title)
    rescue Exception => e
      exception(e)
    end
  end

  def text_extractor(reader, title)
    text = []
    reader.pages.map{|e| text << e.text.scan(/^.+/)}
    state = text[0].select{|e| e.include?("District of")}
    state = state[0].split("of")[1].squish rescue nil
    text  = text.flatten
    title_start = ""
    text.each do |line|
      if title.downcase.include? line.squish.downcase
        title_start = line
        break
      end
    end
    ind     = find_ind(text, title_start )
    article = text[ind..-1].join(" ").squish.gsub("#{title}", "").strip
    teaser  = TeaserCorrector.new(article).correct.strip
    [state, teaser, article]
  end

  def find_ind(text, search_key)
    line = text.select{|e| e.include? search_key}.first
    text.index line
  end

end

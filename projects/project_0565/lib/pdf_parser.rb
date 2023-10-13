class PdfParser
  def initialize
    super
  end

  def fetch_case_filed_date(first_page)
    date_regexp = first_page.match(/((January|JANUARY)|(February|FEBRUARY)|(March|MARCH)|(April|APRIL)|(May|MAY)|(June|JUNE)|(July|JULY)|(August|AUGUST)|(September|SEPTEMBER)|(October|OCTOBER)|(November|NOVEMBER)|(December|DECEMBER)) (Term|TERM), (\d{4})/)
    date = date_regexp.to_s.gsub(/Term|TERM/, "01")
    case_filed_date = Date.parse(date).strftime("%Y-%m-%d")
  end

  def fetch_judge_name(first_page)
    judge_name_regex = first_page.match(/(^PRESENT:|Trial Judge:).*/).to_s
    judge_name = judge_name_regex.sub("PRESENT: ", "")
  end

  def fetch_lower_court_name(first_page)
    court_name_regexp = first_page.match(/(^On Appeal from|On Appeal|APPEALED FROM:).*(?:\n(?!\n{2}).*)*Division$/i).to_s
    lower_court_name_regex = court_name_regexp.gsub(/v\.|\n\s+|\}/, '')
    lower_court_name = lower_court_name_regex.match(/[^On Appeal from|APPEALED FROM:].*/).to_s
  end

  def fetch_status_as_of_date(last_page)
    status_as_of_date = last_page.match(/(Affi)\w+/).to_s
  end

  def remove_extra_space_case_id(case_id)
    case_id_array = []
    case_id_regex = case_id.gsub(/[\n\t]/, " ").squeeze("").strip
    case_ids = case_id_regex.split(",")
    case_ids.each do |case_id|
      case_id_sub_bar = case_id.gsub("/","_")
      case_id_sub_underscore = case_id.gsub("_","")
      case_id_sub_space = case_id.gsub(" ","")
      case_id_array << case_id_sub_space
    end
    case_id_array
  end
end

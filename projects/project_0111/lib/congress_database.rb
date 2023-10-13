
def get_existing_links(links)
  CongressionalRecordJournals.where(link:links).map { |row| row[:link] }
end

def get_existing_links_md5_hash(links)
  CongressionalRecordJournals.where(link:links).map { |row| row[:md5_hash] }
end



def put_data_to_db(record)
  p '_________'
  record_congress = CongressionalRecordJournals.new do |i|
    i.title =    record[:title]
    i.journal = record[:journal].strip if record[:journal]
    i.date =   record[:date]
    i.section =  record[:section].strip if record[:section]
    i.link = record[:link]
    i.text = record[:text] if record[:text].length<3671778
    i.pages = record[:page]
    i.congress_number = record[:congress_number]
    i.congress_period = record[:congress_period]
    i.session = record[:session]
    i.pdf_link = record[:pdf_link]
    i.dirty = record[:dirty] || 0
    i.paragraphs = record[:paragraphs]
    i.clean_text = record[:clean_text] if record[:clean_text].length<2001778
    i.md5_hash = record[:md5_hash]
  end
  record_congress.save
end

def get_row_for_update(limit, year)
  CongressionalRecordJournals.where(congress_number:nil).where('extract(year from date) = ?', year).limit(limit)
end

def add_additional_info_to_record(record, link)
  journal = CongressionalRecordJournals.find_by(link:link)
  journal.congress_number = record[:congress_number]
  journal.congress_period = record[:congress_period]
  journal.session = record[:session]
  journal.pdf_link = record[:pdf_link]
  journal.dirty = record[:dirty] || 0
  journal.paragraphs = record[:paragraphs]
  journal.clean_text = record[:clean_text]

  journal.save
end


def put_departments__to_keywords(dept_id, matched_article_with_value, record_date)

  article_to_db = []

  matched_article_with_value.each do |article_id, value|
    if value[:weight]>2
      article_to_db.push({
                             dept_id: dept_id,
                             article_id: article_id,
                             keyword: value[:keywords],
                             date: record_date
                           })
    end
  end
  p article_to_db
  CongressionalRecordArticleToDepartmentsKeywords.insert_all(article_to_db) unless article_to_db.empty?

end
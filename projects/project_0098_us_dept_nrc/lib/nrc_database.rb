

TABLENAME = 'us_dept_nrc'

def existing_links(year)
  UsDeptNRC.where("YEAR(date)= ?", year).map { |row| row[:link] }
end

def put_data(article)
  p '_________'
  p article
  arcticle_nrc = UsDeptNRC.new do |i|
    i.title =    article[:title].strip
    i.release_no = article[:release_no].strip
    i.teaser =   article[:teaser].strip if article[:teaser]
    i.article =  article[:article].strip if article[:article]
    i.link = article[:link]
    i.type_article = article[:type_article] || 'news'
    i.city = article[:city]
    i.state = article[:state]
    i.date =    article[:date]
    i.contact_info = article[:contact_info]
    i.md5_hash = article[:md5_hash]
  end
  arcticle_nrc.save
end


def put_general_data(article)
  p '_________'
  p article
  arcticle_nrc = UsDeptNRC.new do |i|
    i.title =    article[:title].strip
    i.release_no = article[:release_no].strip
    i.link = article[:link]
    i.date =    article[:date]
    i.md5_hash = article[:md5_hash]
    i.full = 0
  end
  arcticle_nrc.save
end


def update_date(news_short)
  p news_short
  arcticle_nrc = UsDeptNRC.find_by(release_no: news_short[:release_no])
  if arcticle_nrc
    p arcticle_nrc.date
    arcticle_nrc.date = news_short[:date]
    arcticle_nrc.save
  end
end

def get_title(release_nos)
  titles = {}
  UsDeptNRC.where(release_no: release_nos).each do |row|
    titles[row.release_no] = row.title
  end
  titles
end


def delete_null_rows(year)
  UsDeptNRC.where(full:1, article:'').where(article:nil).where('extract(year from date) = ?', year).delete_all
  UsDeptNRC.where(full:1, article:nil).where('extract(year from date) = ?', year).delete_all
  UsDeptNRC.where(full:0).where('extract(year from date) = ?', year).delete_all
end


def put_full_data(article)
  p '_________'
  p article
  arcticle_nrc = UsDeptNRC.find_by(release_no: article[:release_no])
  arcticle_nrc.teaser =   article[:teaser].strip if article[:teaser]
  arcticle_nrc.article =  article[:article].strip if article[:article]
  arcticle_nrc.type_article = article[:type_article] || 'news'
  arcticle_nrc.city = article[:city]
  arcticle_nrc.state = article[:state]
  arcticle_nrc.contact_info = article[:contact_info]
  arcticle_nrc.dirty = article[:dirty] || 0
  arcticle_nrc.full = 1

  arcticle_nrc.save
end
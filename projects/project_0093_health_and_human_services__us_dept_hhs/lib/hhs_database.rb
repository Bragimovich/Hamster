

TABLENAME = 'us_dept_hhs'

def existing_links(year)
  UsDeptHHS.where("YEAR(date)= ?", year).map { |row| row[:link] }
end

def put_date(article)
  p '_________'
  p article
  arcticle_hhs = UsDeptHHS.new do |i|
    i.title =    article[:title].strip
    i.teaser =   article[:teaser].strip if article[:teaser]
    i.article =  article[:article].strip if article[:article]
    i.link = article[:link]
    i.type_article = article[:type_article] || 'news release'
    i.date =    article[:date]
    i.contact_info = article[:contact_info]
    i.dirty = article[:dirty]
    i.md5_hash = article[:md5_hash]
  end
  arcticle_hhs.save
end

def existing_md5_hash(md5_hash)
  UsDeptHHS.where(md5_hash:md5_hash).first
end
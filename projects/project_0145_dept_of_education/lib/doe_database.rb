# frozen_string_literal: true

def insert_all(press_releases)
  press_releases.each do |press_release|
    release = UsDeptEducation.new do |i|
      i.title         = press_release[:title]
      i.date          = press_release[:date]
      i.link          = press_release[:link]
      i.article       = press_release[:article]
      i.teaser        = press_release[:teaser]
      i.contact_info  = press_release[:contact_info]
      i.md5_hash      = press_release[:md5_hash]
    end
    release.save

    article_id = UsDeptEducation.find_by(md5_hash:press_release[:md5_hash]).id

    press_release[:tags].each do |tag|
      tag_db = UsDeptEducationTags.find_by(tag: tag)
      if tag_db.nil?
        UsDeptEducationTags.create(:tag=>tag)
        tag_db = UsDeptEducationTags.find_by(tag: tag)
      end
      tag_id = tag_db.id
      UsDeptEducationTagsArticle.create(article_link_id: article_id, us_dept_education_tag_id:tag_id)
    end
  end
end


def existing_links(links)
  existing_links_array = []
  UsDeptEducation.where(link:links).each {|row| existing_links_array.push(row[:link])}
  existing_links_array
end
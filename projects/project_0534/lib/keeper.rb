require_relative '../models/index'

class Keeper
  def initialize
    @run_object = RunId.new(PoliticoRuns)
    @run_id = @run_object.run_id
  end

  def store(hash)
    link = hash[:link]
    data_to_store = get_objects(hash)
    store_politico(data_to_store[:politico])
    store_politico_authors(data_to_store[:authors])
    store_politico_categories(data_to_store[:categories])
    store_politico_tags(data_to_store[:tags])
    store_politico_authors_article_links(data_to_store[:authors], link)
    store_politico_category_article_links(data_to_store[:categories], link)
    store_politico_tags_article_links(data_to_store[:tags], link)
  end

  def get_objects(hash)
    {
      politico: {
        title: hash[:title],
        teaser: hash[:teaser],
        article: hash[:article],
        date: hash[:date],
        link: hash[:link],
        with_table: hash[:with_table],
        dirty_news: hash[:dirty_news]
      },
      categories: ["Congress"],
      tags: hash[:tags],
      authors: hash[:authors]
    }
  end

  def store_politico(hash)
    exists = Politico.where(link: hash[:link]).as_json.first
    if exists && exists.has_key?("id")
      Politico.update(exists['id'], touched_run_id: @run_id )
    else
      Politico.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_politico_categories(categories)
    categories.each{ |category|
      exists = PoliticoCategory.where(category: category).as_json.first
      hash = { category: category }
      if exists && exists.has_key?("id")
        PoliticoCategory.update(exists['id'], touched_run_id: @run_id )
      else
        PoliticoCategory.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    }
  end

  def store_politico_tags(tags)
    tags.each{ |tag|
      exists = PoliticoTag.where(tag: tag).as_json.first
      hash = { tag: tag }
      if exists && exists.has_key?("id")
        PoliticoTag.update(exists['id'], touched_run_id: @run_id )
      else
        PoliticoTag.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    }
  end

  def store_politico_authors(authors)
    authors.each{ |author|
      exists = PoliticoAuthor.where(author: author).as_json.first
      hash = { author: author }
      if exists && exists.has_key?("id")
        PoliticoAuthor.update(exists['id'], touched_run_id: @run_id )
      else
        PoliticoAuthor.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    }
  end

  def store_politico_category_article_links(categories, link)
    categories.each{ |category|
      cat_check =  PoliticoCategory.where(category: category).as_json.first
      exists = PoliticoCategoryArticleLink.where("article_link='#{link}' and category_id=#{cat_check['id']}").as_json.first
      hash = { category_id: cat_check['id'], article_link: link }
      if exists && exists.has_key?("id")
        PoliticoCategoryArticleLink.update(exists['id'], touched_run_id: @run_id )
      else
        PoliticoCategoryArticleLink.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    }
  end

  def store_politico_authors_article_links(authors,link)
    authors.each{ |author|
      auth_check =  PoliticoAuthor.where(author: author).as_json.first
      exists = PoliticoAuthorArticleLink.where("article_link='#{link}' and author_id=#{auth_check['id']}").as_json.first
      hash = { author_id: auth_check['id'], article_link: link }
      if exists && exists.has_key?("id")
        PoliticoAuthorArticleLink.update(exists['id'], touched_run_id: @run_id )
      else
        PoliticoAuthorArticleLink.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    }
  end

  def store_politico_tags_article_links(tags, link)
    tags.each{ |tag|
      tag_check =  PoliticoTag.where(tag: tag).as_json.first
      exists = PoliticoTagArticleLink.where("article_link='#{link}' and tag_id=#{tag_check['id']}").as_json.first
      hash = { tag_id: tag_check['id'], article_link: link }
      if exists && exists.has_key?("id")
        PoliticoTagArticleLink.update(exists['id'], touched_run_id: @run_id )
      else
        PoliticoTagArticleLink.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    }
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end
  
  def finish
    @run_object.finish
  end
end
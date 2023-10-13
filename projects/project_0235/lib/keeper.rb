# frozen_string_literal: true
require_relative '../models/us_dept_usao'
require_relative '../models/us_dept_usao_tags'
require_relative '../models/us_dept_usao_tag_article_links'
require_relative '../models/us_dept_usao_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(USAORuns)
    @run_id = @run_object.run_id
  end

  def already_inserted_items(flag,tag = nil)
    if flag == 'links'
      USAOM.pluck(:link)
    elsif flag == 'tags'
      USAOMTags.pluck(:tag)
    elsif flag == 'id'
      USAOMTags.where(:tag => tag).pluck(:id)
    end
  end

  def insert_data(data,flag,link = nil)
    if flag == 'USAOM'
      USAOM.insert(data)
    elsif flag == 'USAOMTags'
      USAOMTags.insert(tag: data)
    elsif flag == 'USAOMTALinks'
      USAOMTALinks.insert(tag_id: data, article_link: link)
    end
  end

  def finish
    @run_object.finish
  end

end

# frozen_string_literal: true

class QuDB
  def initialize(host)
    db =
      case host
      when :db02
        'pl_tasks'
      when :dbPL
        'jnswire_prod'
      end
    @db = Mysql2::Client.new(host: host, db: db)
  end

  def story_by(id)
    sql = <<~SQL
      select clean_body as story from pl_tasks.pl_quotation__stories_processed where story_id = #{id};
    SQL

    query(sql).to_a.first[:story]
  end

  def stories_with_quotations
    sql = <<~SQL
      select * from pl_tasks.pl_quotation__stories_processed where quotations <> '';
    SQL

    query(sql).to_a
  end

  def story_meta(id)
    sql = <<~SQL
      select lead_id, published_at as story_published_at, created_at as story_created_at, community_id
      from jnswire_prod.stories where id = #{id};
    SQL

    query(sql).to_a.first
  end

  def save_details(story, metadata, quotation)
    metadata = {} if metadata.nil?
    md5      = Digest::MD5.hexdigest("#{story[:content_type]}#{story[:clean_body]}#{quotation[:text]}")
    values   = [
      story[:story_id],
      metadata[:lead_id] || 0,
      "'#{escape(quotation[:origin])}'",
      "'#{escape(quotation[:possible_origin])}'",
      quotation[:probably_wrong],
      "'#{escape(quotation[:text])}'",
      "'#{metadata[:story_published_at] || '0000-00-00'}'",
      "'#{metadata[:story_created_at] || '0000-00-00'}'",
      metadata[:community_id] || 0,
      "'#{story[:content_type]}'",
      "'#{md5}'"
    ].join(', ')

    sql = <<~SQL
      insert ignore into pl_tasks.pl_quotation__details (story_id, lead_id, found_person, matched_person, probably_wrong, quotation, story_published_at, story_created_at, community_id, content_type, md5)
      value (#{values});
    SQL

    query(sql)
  end

  def close
    @db.client.close
  end

  private

  def query(sql, sk = true)
    resp = nil

    retries = 0
    begin
      resp = @db.client.query(sql, symbolize_keys: sk)
    rescue => e
      retries += 1
      sleep 0.5
      retry if retries <= 10

      puts "\n#{sql}\n\n#{e.message}"
      exit 1
    end

    resp
  end
end

def escape(str)
  str = str.to_s.strip.squeeze('')
  return '' if str == ''
  str.gsub(/\\/i, '\\\\\\\\').gsub("'", "\\\\'").gsub('"', "\\\\\"")
end

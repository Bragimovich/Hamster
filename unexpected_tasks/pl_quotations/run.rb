# frozen_string_literal: true

require_relative 'lib/qu_array'
require_relative 'lib/qu_db'
require_relative 'lib/qu_processor'
require_relative 'lib/qu_re'

def run(*options)
  id    = options.select { |opt| opt =~ %r{--id=\d+} }
  id    = id.empty? ? nil : id.first.split('=').last
  meta  = options.select { |opt| opt =~ %r{--meta=\d+} }
  meta  = meta.empty? ? nil : meta.first.split('=').last
  save  = options.select { |opt| opt =~ %r{--save=\d+} }
  save  = save.empty? ? nil : save.first.split('=').last
  db_02 = QuDB.new(:db02)
  db_pl = QuDB.new(:dbPL)

  begin
    if id
      pp QuProcessor.new(db_02.story_by(id)).story_analysis
    elsif meta
      pp db_pl.story_meta(meta)
    elsif save
      # TODO: need to write something here
    else
      stories = db_02.stories_with_quotations
      size    = stories.size

      stories.each_with_index do |story, index|
        metadata   = db_pl.story_meta(story[:story_id])
        quotations = QuProcessor.new(story[:clean_body]).story_analysis[:quotations]

        quotations.each { |quotation| db_02.save_details(story, metadata, quotation) }

        print "\r#{size} | #{index + 1}"
      end
    end
  rescue Interrupt
    puts
    puts "\rInterrupted by user"
    exit 0
  ensure
    puts

    db_02.close
    db_pl.close
  end
end

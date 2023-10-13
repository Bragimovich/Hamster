# frozen_string_literal: true

module Hamster
  def self.do
    @scrapers        = Scrapers.all
    Scrapers.connection.close
    @unexpected_task = unexpected_task

    single   = !@arguments[:single].nil?
    instance = @arguments[:instance]
    name     = @unexpected_task.gsub(/unexpected_task\/(.*)$/, '\1')
    task     = single ? name : "#{name}-#{instance}"

    load @unexpected_task + '.rb'

    log "Unexpected task #{task} was run.", :green

    begin
      eval(unexpected_task.camelize + ".run(**#{@arguments})")
    rescue Interrupt || SystemExit
      log "\nUnexpected task #{task} was interrupted by user.", :yellow
      exit 0
    rescue Exception => e
      log @debug ? e.full_message : e
      exit 1
    end

    log "Unexpected task #{task} has done.", :green
    exit 0
  end
end


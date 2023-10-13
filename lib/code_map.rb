# frozen_string_literal: true

module Hamster
  def self.start_trace
    code_map = CodeMapStore.new
    data = []
    trace = TracePoint.new(:call) do |tp|
      if tp.path.match(/hamster\/lib|hamsterprojects\/lib/i)
        code_map.store("#{File.basename(tp.path)}##{tp.method_id}")
      end
    end

    trace.enable
    yield
    trace.disable
    code_map.flush
  end

  class CodeMapStore
    def initialize
      @flushed_at = Time.now
      @data = []
    end

    def store(method)
      item = @data.select{|r| r[:method] == method}.first
      if item
        item[:count] = item[:count] + 1
      else
        @data << { method: method, count: 1}
      end
      flush() if @flushed_at < Time.now - (30 * 60)
    end

    def flush
      @sql_data = []

      return if @data.count.zero?

      @data.each do |item|
        record = CodeMap.find_by(method: item[:method])
        @sql_data << { method: item[:method], count: item[:count] + record&.count.to_i }
      end
      CodeMap.upsert_all(@sql_data)
      @data = []
      @flushed_at = Time.now
      Hamster.close_connection(CodeMap)
    end
  end

  # CREATE TABLE `code_maps`
  # (
  #   `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  #   `method`          VARCHAR(255),
  #   `count`           BIGINT DEFAULT 1,
  #   UNIQUE KEY `method` (`method`)
  # ) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;
  class CodeMap < ActiveRecord::Base
    storage = Storage.use(host: :db02, db: :hle_resources)
    establish_connection(storage) if storage
    self.table_name = 'code_maps'
  end
end


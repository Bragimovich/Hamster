# frozen_string_literal: true

# roo = Roo::Spreadsheet.open(path)
# roo.each_with_pagename do |name, sheet|
#   next if name == 'Cumulative Summary'
# end

require_relative '../models/rpc_runs'
require_relative '../lib/validate_error.rb'

require 'roo'

class Parser < Hamster::Harvester

  def initialize
    super

    @years = commands[:years].is_a?(Integer) || commands[:years] == 'all' ? commands[:years] : raise(ValidateError, 'Incorrect `years`, should be year number or "all".')

    run = C19VRuns.all.to_a.last
    @run_id = run && %w(processing error pause scraped).include?(run[:status]) ? run[:id] : (commands[:run_id] || raise(ValidateError, 'No active or scraped scrapings.'))

    @tries = 0

    @start_time = Time.now
  end

  def main

    # while check_time && !no_pages_left?
    #   get_folders
    #   @pages_folders.each do |folder|
    #     break unless check_time
    #
    #     @semaphore = Mutex.new
    #
    #     list = @_peon_.give_list(subfolder: folder)
    #
    #     ​threads = Array.new(commands[:threads] || 1) do
    #       Thread.new do
    #         t_files = []
    #         @semaphore.synchronize {
    #           t_files = list.pop(10)
    #         }
    #         Thread.exit if t_files.size.zero? && list.count.zero?
    #
    #         t_files.each do |file_name|
    #           file = @_peon_.give(file: file_name, subfolder: folder)
    #
    #           break unless file.is_a? String
    #           Nokogiri::HTML.parse(file).css('ul.views-row li').each do |row|
    #             ein = row.at('.search-excerpt span:first-child').text[/\d+-\d+/].delete('-')
    #             org_name = row.at('.result-orgname a').text.strip
    #             org_link = row.at('.result-orgname a')['href']
    #             org_parens = row.at('.result-orgname i') ? row.at('.result-orgname i').text.strip[1..-2].strip : nil
    #             org_state = row.at('.search-excerpt span:nth-child(3)').text.delete(',').strip
    #             org_city = row.at('.search-excerpt span:nth-child(2)').text.delete(',').strip
    #
    #             h = {
    #                 ein: ein,
    #                 org_name: org_name,
    #                 org_name_parens: org_parens,
    #                 state: org_state,
    #                 city: org_city,
    #                 org_link: org_link
    #             }
    #
    #             new_md5 = Digest::MD5.hexdigest(h.to_s)
    #
    #             begin
    #               check = IrsNonprofitOrgs.where("ein = #{ein} AND deleted != 1").as_json.first
    #
    #               if check && check['md5_hash'] == new_md5
    #                 IrsNonprofitOrgs.update(check['id'], touched_run_id: @run_id)
    #               elsif check
    #                 IrsNonprofitOrgs.update(check['id'], deleted: true)
    #                 IrsNonprofitOrgs.insert_ignore_into(h.merge({run_id: @run_id, touched_run_id: @run_id, md5_hash: new_md5}))
    #               else
    #                 IrsNonprofitOrgs.insert_ignore_into(h.merge({run_id: @run_id, touched_run_id: @run_id, md5_hash: new_md5}))
    #               end
    #             ensure
    #               IrsNonprofitOrgs.clear_active_connections!
    #             end
    #           end
    #
    #           @_peon_.move(file: file_name, from: folder, to: folder)
    #         end
    #       end
    #     end
    #
    #     ​threads.each(&:join)
    #   end
    # end
  rescue ValidateError => e
    p e.message
  rescue => e
    p e.backtrace
    p e.message
  else
    run = C19VRuns.all.to_a.last
    if @run_id && run && run[:status] == 'scraped'
      C19VRuns.update(@run_id, {status: 'finished'})
      Covid19Vaccination.where("touched_run_id != ?", @run_id).update_all(deleted: true)
    end
  end

  def process_page(page)

  end

  private

  def get_path
    @pages_folders = Dir["#{storehouse}store/orgs_list_pages/*/"].map {|s| s.gsub("#{storehouse}store/", '')}
  end

  def no_pages_left?
    Dir["#{storehouse}store/orgs_list_pages/*/*.gz"].size.zero?
  end

  def check_time
    (Time.now - @start_time) / 60 < 600
  end
end

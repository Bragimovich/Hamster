# frozen_string_literal: true

require_relative '../models/db_observer_models'

SKIP_LIST = %i(db09)
# Class for working with a database
class Keeper
  # Get all scrapers with their associated Slack channel
  #
  # @return [Hash<String, String>] A hash mapping scraper names to Slack channel IDs
  def scrapers
    sql = "SELECT name, slack FROM `scrapers`"
    ScrapeTasksAttachedTables.connection.execute(sql).to_a.to_h.merge({'Art Jarocki'=> ART_JAROCKI_SLACK_ID })
  end

  # Get a list of all tables in the databases
  #
  # @return [Array<String>] A list of table names in the databases
  def all_tables
    res = []
    databases = Storage.new.methods.sort.filter {|el| el =~ /db\d+/} # all db.. excluding dbRS, dbPL etc.
    databases.each do |host|
      next if host.in?(SKIP_LIST)
      sql = "select concat_ws('.','#{host.upcase}',table_schema,table_name) from information_schema.tables;"
      ActiveRecord::Base.establish_connection(Storage[host: host, db: :mysql])
      res += ActiveRecord::Base.connection.execute(sql).to_a.flatten
    rescue RuntimeError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid  => e
      puts e.class, e
    end
    res
  end

  # Store the state of all scrape tasks
  #
  # @param tasks_state [Array<Hash>] A list of hashes representing the state of each scrape task
  def store_all(tasks_state)
    ScrapeTasksAttachedTables.insert_all(tasks_state) unless tasks_state.empty?
  end

  # Get the last state of all scrape tasks
  #
  # @return [Array<Hash>] A list of hashes representing the state of each scrape task
  def tasks_last_state
    # puts '*'*77, sql = "SELECT id, task_number, current_state FROM `scrape_tasks_attached_tables` where deleted = 0 order by id asc"
    sql = "SELECT id, task_number, current_state FROM `scrape_tasks_attached_tables` where deleted = 0 order by id asc"
    ScrapeTasksAttachedTables.connection.exec_query(sql).to_a
  end

  # Update the state of scrape tasks
  #
  # @param ids_with_deleted [Array<Hash>] A list of hashes representing the state of each scrape task
  def update_all(ids_with_deleted)
    deleted_ids = ids_with_deleted.map {|el| el["id"] if el["deleted"]}.compact
    remained_ids = ids_with_deleted.map {|el| el["id"] unless el["deleted"]}.compact
    ScrapeTasksAttachedTables.where(:deleted => false).update_all(:deleted => true)
    ScrapeTasksAttachedTables.where(:id => remained_ids).update_all(:deleted => false)
  end

  # Get all sent message records
  #
  # @return [Array<Hash>] A list of hashes representing sent message records for each task
  def all_sent_records
    sql = "SELECT task_number, sent_counter, updated_at FROM `scrape_tasks_attached_tables_sent_counter`"
    ScrapeTasksAttachedTablesSentCounter.connection.exec_query(sql).to_a
  end

  # Reset the sent message counter for the specified tasks
  #
  # @param task_number_list [Array<Integer>] A list of task numbers to reset the counter for
  def reset_sent_counter(task_number_list)
    ScrapeTasksAttachedTablesSentCounter.where(:task_number => task_number_list).update_all(:sent_counter => 0)
  end

  # Store records for all problems encountered
  #
  # @param task_number_list [Array<Integer>] A list of task numbers with problems
  def store_all_problems(task_number_list)
    ScrapeTasksAttachedTablesSentCounter.insert_all(task_number_list.map {|el| {"task_number" => el}}) unless task_number_list.empty?
    increment_sent_counter(task_number_list)
  end

  # Increment the sent counter for the given task numbers.
  #
  # @param task_number_list [Array<Integer>] The list of task numbers to increment the sent counter for.
  def increment_sent_counter(task_number_list)
    ScrapeTasksAttachedTablesSentCounter.where(:task_number => task_number_list).update_all("sent_counter = sent_counter + 1")
  end

  # Get the task numbers and their corresponding sent counter values where the sent counter is 1, 24, 48, 60, 66 or a multiple of 3 greater than 68.
  #
  # @return [Hash<Integer, Integer>] The task numbers and their corresponding sent counter values that meet the above criteria.
  def sent_candidates
    sql = "SELECT task_number, sent_counter FROM `scrape_tasks_attached_tables_sent_counter` where sent_counter in (1, 24, 48, 60, 66) or (sent_counter > 68 and sent_counter mod 3 = 0)"
    ScrapeTasksAttachedTablesSentCounter.connection.execute(sql).to_a.to_h
  end
end

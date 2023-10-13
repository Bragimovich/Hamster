# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'

class ScrapedTablesCheckerManager
  # Initializes a new instance of ScrapedTablesCheckerManager.
  def initialize
    @keeper = Keeper.new
    @parser = Parser.new
    @db_tables = @keeper.all_tables.sort
    @databases = @db_tables.map {|el| el.split('.').first}.uniq.sort
    @scrapers = @keeper.scrapers
    @all_sent_records = @keeper.all_sent_records
  end

  # This method is using for debugging or to do some checks.
  #
  # @return [void]
  def check
    pp @keeper.sent_candidates
  end

  # Runs the checker.
  #
  # @return [void]
  def run
    tasks_list = @parser.tasks_with_tables_list
    tasks_current_state = tasks_state(tasks_list)
    tasks_last_state = @keeper.tasks_last_state
    @keeper.update_all(id_with_deleted!(tasks_current_state, tasks_last_state))
    @keeper.store_all(tasks_current_state - tasks_last_state) # Matrix Subtraction

    missing_tables = []
    tasks_list.each do |task|
      next unless task[:status].in?(CHECKED_STATUSES)
      task[:tables].reject! {|table| skip?(table)}
      missing_tables.push(task) unless task[:tables].empty?
    end

    tasks_with_problems = missing_tables.map {|el| el[:task_number]}
    tasks_to_reset = all_tasks - tasks_with_problems
    @keeper.reset_sent_counter(tasks_to_reset)
    @keeper.store_all_problems(tasks_with_problems)
    @candidates = @keeper.sent_candidates
    send(missing_tables.select {|task| task[:task_number].in?(@candidates.keys)})

    pp "All Things Done!!!"
  end

  # Checks table presence in tables list and it's database presence in DBs list
  #
  # @param table_name [String] name of the table in format `DB02.hle_resources.scrapers`.
  # @return [boolean]
  #   TRUE if the table exists in the corresponding database
  #   TRUE if table's database is excluded from the validation list
  #   FALSE in all other cases
  #
  def skip?(table_name)
    db_name = table_name.split('.').first
    table_name.in?(@db_tables) || !db_name.in?(@databases)
  end

  # Sends an alert for each task in the specified list.
  #
  # @param alert_list [Array<Hash>] List of tasks to send alerts for.
  # @return [void]
  def send(alert_list)
    alert_list.each do |task|
      message = <<~message
      *!!!   ALARM   !!!*
      <@#{@scrapers[task[:scraper]]}>, you have missing tables in task <#{LOKIC_URL}#{task[:task_number]}|#{task[:task_number]}>
      #{task[:tables].map {|table| "• #{table}\n"}.join.chomp}
      message
      message += cc(task)
      Slack::Web::Client.new.chat_postMessage(
        channel: CHANNEL,
        text: message,
        as_user: true)
    end
  end

  # Generates the CC part of the alert message.
  #
  # @param task [Hash] Task to generate the CC for.
  # @return [String] The CC part of the alert message.
  def cc(task)
    text = ''
    text += "\n*CC:* <@#{@scrapers[task[:created_by]]}>" if @candidates[task[:task_number]] > 23
    text += ", <@#{ART_JAROCKI_SLACK_ID}>" if @candidates[task[:task_number]] > 47
    text += ", <!channel>" if @candidates[task[:task_number]] > 70
    text
  end

  # Generates a list of task states for the specified tasks.
  #
  # @param tasks [Array<Hash>] List of tasks to generate states for.
  # @return [Array<Hash>] List of task states.
  def tasks_state(tasks)
    tasks.map do |task|
      { task_number:    task[:task_number],
        current_state:  current_state(task)
      }.stringify_keys
    end
  end

  # Returns the current state of a given task, including the scraper name and the state of its tables.
  #
  # @param task [Hash] A hash containing the task number, scraper name, and an array of tables.
  # @return [String] A JSON-formatted string with the task's current state.
  def current_state(task)
    { scraper:        task[:scraper],
      tables_state:   tables_state(task[:tables])
    }.to_json
  end

  # Returns the state of each table in a given array, including its location and whether it is present in the database.
  #
  # @param tables [Array<String>] An array of table names.
  # @return [Array<Hash>] An array of hashes containing the table name and a boolean indicating its presence in the database.
  def tables_state(tables)
    tables.map do |table|
      { table_location: table, table_presence: @db_tables.include?(table) }
    end
  end

  # Maps the IDs of existing tasks to a boolean indicating whether they have been modified or not, based on a comparison with new task data.
  #
  # @param new_data [Array<Hash>] An array of hashes representing new task data.
  # @param last_data [Array<Hash>] An array of hashes representing the previous state of tasks.
  # @return [Array<Hash>] An array of hashes containing the task ID and a boolean indicating whether the task has been modified or not.
  def id_with_deleted!(new_data, last_data) # !!! last_data changes both inside and outside this method
    last_data.map do |task|
      {
        id:       task.delete("id"), # calling this method causes 'side-effect' but it is part of the algorythm
        deleted:  !new_data.include?(task)
      }.stringify_keys
    end
  end

  # Returns an array of all task numbers in the @all_sent_records instance variable.
  #
  # @return [Array<Integer>] An array of integers representing task numbers.
  def all_tasks
    @all_sent_records.map {|row| row["task_number"]}
  end
end

# frozen_string_literal: true

# A class for parsing scrape tasks by using LokiC api.
class Parser
  # Returns a list of tasks with attached tables.
  #
  # @return [Array<Hash>] A list of tasks with attached tables.
  def tasks_with_tables_list
    response = Hamster.connect_to(API_URL).body
    tasks = JSON.parse(response)
    tasks.select! {|el| el["has_data_location"]}
    tasks.map {|el| api(el["number"])}.compact
  end

  # Sends an API request for certain task.
  #
  # @param task_number [Integer] The number of the task to retrieve.
  # @return [Hash] A hash containing information about task.
  def api(task_number)
    link = "#{API_URL}#{task_number}"
    res = Hamster.connect_to(link).body
    task = JSON.parse(res)
    { task_number:  task_number,
      scraper:      task["main_info"]["scraper"],
      created_by:   task["created_by"],
      status:       task["status"],
      tables:       task["main_info"]["table_locations"]
    }
  end
end

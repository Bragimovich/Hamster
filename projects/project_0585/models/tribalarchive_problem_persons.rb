# frozen_string_literal: true

require_relative 'raw_tributearchiveable'
class TribalarchiveProblemPersons < ActiveRecord::Base
  include RawTributearchiveable

  self.table_name = 'tribalarchive_problem_persons'
end

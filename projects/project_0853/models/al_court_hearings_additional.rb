# frozen_string_literal: true

require_relative 'al_inmateable'
class AlCourtHearingsAdditional < ActiveRecord::Base
  include AlInmateable

  self.table_name = 'al_court_hearings_additional'
end

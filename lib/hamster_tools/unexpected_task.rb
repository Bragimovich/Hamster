# frozen_string_literal: true

module Hamster
  module HamsterTools
    def unexpected_task
      "unexpected_tasks/#{@arguments[:do]}"
    end
  end
end

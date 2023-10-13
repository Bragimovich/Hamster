# frozen_string_literal: true

require_relative 'tx_fort_bend_inmateable'
class TxFortBendMugshot < ActiveRecord::Base
  include TxFortBendInmateable
end

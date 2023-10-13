# frozen_string_literal: true

require_relative 'nj_doc_inmateable'
class NjDocMugshot < ActiveRecord::Base
  include NjDocInmateable
end

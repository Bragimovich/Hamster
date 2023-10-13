# frozen_string_literal: true

class TestMigration < ActiveRecord::Migration[5.2]
  def self.up
    create_table :test_migration do |t|
      t.string :column
      t.string :test
    end
  end
 
  def self.down
    drop_table :test_migration
  end
end

# frozen_string_literal: true

MAIN_TABLE = 'us_sheriffs_info'

require_relative '../models/models'

class  Keeper
  def initialize
    super
    @run_id = Runs.create.id
  end

  def store_to_db(sheriffs_data)
    res = Runs.find(@run_id)
    puts ['*'*77, "Store sheriffs_data to DataBase"]

    md5_sheriffs_info = MD5Hash.new(:columns => %w(sheriff county address1 address2 city state zip phone website))
    sheriffs_data.each {|el| el.merge!({run_id: @run_id, touched_run_id: @run_id, md5_hash: md5_sheriffs_info.generate(el)})}
    UsSheriffsInfo.insert_all(sheriffs_data)

    md5_hash_array = sheriffs_data.map {|el| el[:md5_hash]}
    update_touch_id(md5_hash_array)
    mark_deleted

    res.status = 'finish'
    res.save
  end

  def update_touch_id(md5_hash_array)
    UsSheriffsInfo.where(:md5_hash => md5_hash_array).update_all(:touched_run_id => @run_id, :deleted => 0) unless md5_hash_array.empty?
  end

  def mark_deleted
    UsSheriffsInfo.where.not(:touched_run_id => @run_id).update_all(:deleted => 1)
  end
end

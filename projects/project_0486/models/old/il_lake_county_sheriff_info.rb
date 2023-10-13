
class IlValidateMd5Hash < ActiveModel::Validator
  def validate(record)
    v_str = record.gen_md5
    find_record = IlLakeCountySheriffInfo.find_by(md5_hash: v_str)
    if !find_record.nil?
      record.errors.add :md5_hash, "Dublicate md5_hash!"
      find_record.update(touched_run_id: record.run_id)
    end
  end
end

class IlLakeCountySheriffInfo < ActiveRecord::Base

  self.table_name = 'il_lake_county_sheriff_info'
  establish_connection(Storage[host: :db11, db: :usa_raw])
  has_many :activities, class_name: "IlLakeCountySheriffActivities", foreign_key: :info_id
  validates_with IlValidateMd5Hash, on: :create, presence: true
  before_create :add_md5

  def add_md5
    self.md5_hash = gen_md5
    self.touched_run_id = self.run_id
  end

  def gen_md5
    str = self.attributes.map do |key, attr|
      if (key != "id" && key != "run_id" && key != "created_by" && key != "created_at" && key != "updated_at" && key != "touched_run_id" && key != "deleted" && key != "md5_hash")
        attr
      end
    end.compact.join("|")
    Digest::MD5.hexdigest str
  end

end

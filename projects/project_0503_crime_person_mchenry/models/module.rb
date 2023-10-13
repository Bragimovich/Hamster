module ModelsHelpers

  DB_SCHEME = :crime_perps__step_1
  DB_SERVER = :db01

  def add_md5
    self.md5_hash = gen_md5
    self.touched_run_id = self.run_id
  end

  def gen_md5
    str = self.attributes.map do |key, attr|
      attr if (key != 'id' && key != 'run_id' && key != 'created_by' && key != 'created_at' && key != 'updated_at' && key != 'touched_run_id' && key != 'deleted' && key != 'md5_hash')
    end.compact.join('|')
    Digest::MD5.hexdigest str
  end

  class IlValidateMd5Hash < ActiveModel::Validator
    def validate(record)

      class_validate = options[:class_name]
      v_str = record.gen_md5
      find_record = class_validate.find_by(md5_hash: v_str)
      record.errors.add :md5_hash, "Dublicate md5_hash #{class_validate.class}!" unless find_record.nil?
    end
  end

  def after_validation_toucher_run_id

  end
end
require_relative '../models/id_agency_heads'
require_relative '../models/id_employee_pay_rate'
require_relative '../models/id_employment_history'
require_relative '../models/id_run'

class Keeper
  attr_reader :run_id

  def initialize(**options)
    super

    @run_object = RunId.new(IdRun)
    @run_id = @run_object.run_id
  end

  def store_run_id(data, model)
    if model ==  IdAgencyHeads
      store_agency_head(data, model)
    else
      store_id(data, model)
    end

  end

  def store_agency_head(data, model)
    if model.find_by(name: data[:name])
      existing_data =  data.merge!(touched_run_id: run_id)
      insert_model(model, existing_data)
    else
      existing_data =  data.merge!(run_id: run_id,touched_run_id: run_id)
      model.insert(existing_data)
    end
  end

  def store_id(data, model)
    if model.find_by(employee_name: data[:employee_name])
      update_data =  data.merge!(touched_run_id: run_id)
      insert_model(model, update_data)
    else
      update_data =  data.merge!(run_id: run_id,touched_run_id: run_id)
      model.insert(update_data)
    end
  end

  def insert_model(model, hash)
    if model == IdAgencyHeads
      existing = model.find_by(name: hash[:name])
    else
      existing = model.find_by(employee_name: hash[:employee_name])
    end

    unless existing.nil?
      if hash != existing
        begin
          existing.update(hash)
        rescue Exception => e
          Hamster.logger.error(e.full_message)
          Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
        end
      end
    else
      model.insert(hash)
    end
  end

  def save_new_data(data, model)
    existing_data =  data.merge!(run_id: run_id,touched_run_id: run_id)
    model.insert(existing_data)
  end

  def mark_delete
    models = [IdAgencyHeads, IdEmployeePayRate, IdEmploymentHistory]
    models.each do |model|
      model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  def finish
    @run_object.finish
  end

end

# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  manager.store_general_info
  begin
    if options[:store_enrollment]
      manager.store_enrollment
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Enrollment", use: :slack)
    elsif options[:store_graduation]
      manager.store_graduation
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Graduation", use: :slack)
    elsif options[:store_growth]
      manager.store_growth
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Growth", use: :slack)
    elsif options[:store_salary]
      manager.store_salary
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Salary", use: :slack)
    elsif options[:store_assessment]
      manager.store_assessment
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Assessment", use: :slack)
    elsif options[:store_discipline]
      manager.store_discipline
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Discipline", use: :slack)
    else
      manager.store_graduation
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Graduation", use: :slack)
      manager.store_growth
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Growth", use: :slack)
      manager.store_assessment
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Assessment", use: :slack)
      manager.store_discipline
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Discipline", use: :slack)
      manager.store_enrollment
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Enrollment", use: :slack)
      manager.store_salary
      report(to: 'Hatri', message: "Finish Run project 687 -- storing data to DB Salary", use: :slack)
    end
    report(to: 'Hatri', message: "Projects 687 finish running and store all data to DB", use: :slack)
  rescue Exception => e
    report(to: 'Hatri', message: "Projects 687 #{e.full_message}", use: :slack)
  end
end

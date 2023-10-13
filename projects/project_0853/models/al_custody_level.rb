# frozen_string_literal: true

require_relative 'al_inmateable'
class AlCustodyLevel < ActiveRecord::Base
  include AlInmateable

  def self.generate_custody_levels
    {
    'Close' => 'The most restrictive custody level to which an inmate can be assigned. Inmates in this custody will be housed in a single cell in a close security institution. Movement outside the housing area requires that the inmate be restrained and accompanied by armed correctional personnel in accordance with Administrative Regulations and Standard Operating Procedures.',
    'Minimum-in' => 'Appropriate for inmates who do not pose a significant risk to self or others within the confines of the institution. Work assignments must be on-property at a minimum, medium, or close security facility and may be supervised by non-security personnel with the express approval of the Warden/designee.',
    'Minimum-out' => 'Appropriate for inmates that do not pose a significant risk to self or others and suitable to be assigned off-property work details without the direct supervision of correctional officers. Inmates must remain in prison clothing at all times and work is generally assigned to only government positions (i.e. city, county, ADOC, ADOT, etc.).Inmates in this custody are generally assigned to Community Work Centers (CWC) with higher security facilities only maintain a small number of job assignments requiring minimal supervision.',
    'Minimum-community' => 'This custody level is appropriate for those inmates who have demonstrated the ability to adjust to semi-structured environment and/or those inmates who are nearing the end of their incarceration in order to transition and reintegrate back into the community. Inmates in this custody are allowed gainful employment in the community on a full-time basis and will be supervised in community based facilities when not working.',
    'Minimum' => 'The lowest custody designation an inmate can receive. In general, Minimum custody inmates are conforming to ADOC rules and regulations. There are three levels of Minimum custody.',
    'Medium' => 'Less secure than Close security and is for those inmates who have demonstrated less severe behavioral problems. Inmates in this category are considered to be suitable for participation in formalized institutional treatment programs, work assignments or other activities within the confines of an institution. Inmates should be able to adapt to dormitory living or to double occupancy cells. Inmates in this custody will be housed in a medium or close security institution. Supervision by armed correctional personnel is required when outside of the institution.'
    }.each do |k,v|
      find_or_create_by(level: k.upcase, description: v, data_source_url: 'http://www.doc.state.al.us/Definitions')
    end
  end

  def self.find_with(level)
    case level
    when 'MIN-IN'
      find_by(level: 'Minimum-in'.upcase)
    when 'MIN-OUT'
      find_by(level: 'Minimum-out'.upcase)
    when 'MIN-COMM'
      find_by(level: 'Minimum-community'.upcase)
    else
      find_by(level: level)
    end
  end
end

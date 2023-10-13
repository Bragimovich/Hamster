class RawCaContraCostaCountyInmatesArrestsCharges< ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :foia_inmate_gather])
    self.table_name = 'raw_ca__contra_costa_county_inmates__arrests_charges'
    self.inheritance_column =:_type_disabled
end
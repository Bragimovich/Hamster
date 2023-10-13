require_relative '../models/open_society_foundations_awarded_grants'

class DBKeeper
  def store(hash)
    OpenSocietyFoundationsAwardedGrants.insert(hash)
  end
end
  
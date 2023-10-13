
class String
  def to_camel_case
    self.split(/_/).map(&:capitalize).join
  end

  def snake_case
    self.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
  end
end
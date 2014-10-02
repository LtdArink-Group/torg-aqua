module Model::Lookup
  def self.extended(base)
    base.instance_variable_set(:@values, {})
  end

  def lookup(key)
    return @values[key] if @values.key? key
    object = self.find(key)
    @values[key] = object.nil? ? nil : object.send(value_attribute)
  end

  def value_attribute
    @attributes.first
  end
end

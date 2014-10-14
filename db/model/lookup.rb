module Model::Lookup
  def self.extended(base)
    base.instance_variable_set(:@values, {})
  end

  def lookup(*keys)
    return @values[keys] if @values.key? keys
    object = find(*keys)
    @values[keys] = object.nil? ? nil : object.send(value_attribute)
  end

  def value_attribute
    @attributes.first
  end
end

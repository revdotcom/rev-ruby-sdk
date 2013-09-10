module Rev
  # Utility class with instance methods for hash/JSON conversion
  class ApiSerializable

    # Map given hash to instance properties
    #
    # @param fields [Hash] of fields to initialize instance. See instance attributes for available fields.
    def initialize(fields = {})
      fields.each { |k,v| self.instance_variable_set("@#{k.to_sym}", v) if self.methods.include? k.to_sym }
    end

    # Recursively convert object to hash
    # @note http://stackoverflow.com/questions/1684588/how-to-do-ruby-object-serialization-using-json
    #
    # @return [Hash] hash map of the object including all nested children
    def to_hash
      h = {}
      instance_variables.each do |e|
        o = instance_variable_get e.to_sym
        h[e[1..-1]] = (o.respond_to? :to_hash) ? o.to_hash : o;
      end
      h
    end

    # Recursively convert object to JSON (internally utilizing hash)
    def to_json *args
      to_hash.to_json *args
    end
  end
end

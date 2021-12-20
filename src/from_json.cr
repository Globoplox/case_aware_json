# Override some stdlib methods to hanlde convention
def Union.new(pull : JSON::PullParser)
  location = pull.location

  {% begin %}
    case pull.kind
    {% if T.includes? Nil %}
    when .null?
      return pull.read_null
    {% end %}
    {% if T.includes? Bool %}
    when .bool?
      return pull.read_bool
    {% end %}
    {% if T.includes? String %}
    when .string?
      return pull.read_string
    {% end %}
    when .int?
    {% type_order = [Int64, UInt64, Int32, UInt32, Int16, UInt16, Int8, UInt8, Float64, Float32] %}
    {% for type in type_order.select { |t| T.includes? t } %}
      value = pull.read?({{type}})
      return value unless value.nil?
    {% end %}
    when .float?
    {% type_order = [Float64, Float32] %}
    {% for type in type_order.select { |t| T.includes? t } %}
      value = pull.read?({{type}})
      return value unless value.nil?
    {% end %}
    else
      # no priority type
    end
  {% end %}

  {% begin %}
    {% primitive_types = [Nil, Bool, String] + Number::Primitive.union_types %}
    {% non_primitives = T.reject { |t| primitive_types.includes? t } %}

    # If after traversing all the types we are left with just one
    # non-primitive type, we can parse it directly (no need to use `read_raw`)
    {% if non_primitives.size == 1 %}
      return {{non_primitives[0]}}.new(pull)
    {% else %}
      string = pull.read_raw
      {% for type in non_primitives %}
        begin
          if pull.responds_to? :convention            
            return {{type}}.from_json(string, pull.convention)
          else
            return {{type}}.from_json(string)
          end
        rescue JSON::ParseException
          # Ignore
        end
      {% end %}
      raise JSON::ParseException.new("Couldn't parse #{self} from #{string}", *location)
    {% end %}
  {% end %}
end

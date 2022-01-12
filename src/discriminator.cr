module JSON
  module Serializable
    
    # This an override of the std lib `JSON::Serializable::use_json_discriminator` that add an optional default target class and support for CAJ.
    #
    # Tells this class to decode JSON by using a field as a discriminator.
    #
    # - *field* must be the field name to use as a discriminator
    # - *mapping* must be a hash or named tuple where each key-value pair
    #   maps a discriminator value to a class to deserialize
    #
    # For example:
    #
    # ```
    # require "json"
    #
    # abstract class Shape
    #   include JSON::Serializable
    #
    #   use_json_discriminator "type", {point: Point, circle: Circle}
    #
    #   property type : String
    # end
    #
    # class Point < Shape
    #   property x : Int32
    #   property y : Int32
    # end
    #
    # class Circle < Shape
    #   property x : Int32
    #   property y : Int32
    #   property radius : Int32
    # end
    #
    # Shape.from_json(%({"type": "point", "x": 1, "y": 2}))               # => #<Point:0x10373ae20 @type="point", @x=1, @y=2>
    # Shape.from_json(%({"type": "circle", "x": 1, "y": 2, "radius": 3})) # => #<Circle:0x106a4cea0 @type="circle", @x=1, @y=2, @radius=3>
    # ```
    macro caj_use_json_discriminator(field, mapping, default = nil)
      {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
        {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
      {% end %}

      def self.new(pull : ::JSON::PullParser)
        location = pull.location

        discriminator_value = nil

        # Try to find the discriminator while also getting the raw
        # string value of the parsed JSON, so then we can pass it
        # to the final type.
        json = String.build do |io|
          JSON.build(io) do |builder|
            builder.start_object
            pull.read_object do |key|
              if key == {{field.id.stringify}}
                value_kind = pull.kind
                case value_kind
                when .string?
                  discriminator_value = pull.string_value
                when .int?
                  discriminator_value = pull.int_value
                when .bool?
                  discriminator_value = pull.bool_value
                else
                  raise ::JSON::SerializableError.new("JSON discriminator field '{{field.id}}' has an invalid value type of #{value_kind.to_s}", to_s, nil, *location, nil)
                end
                builder.field(key, discriminator_value)
                pull.read_next
              else
                builder.field(key) { pull.read_raw(builder) }
              end
            end
            builder.end_object
          end
        end

        unless discriminator_value
          raise ::JSON::SerializableError.new("Missing JSON discriminator field '{{field.id}}'", to_s, nil, *location, nil)
        end
        
        case discriminator_value
        {% for key, value in mapping %}
          {% if mapping.is_a?(NamedTupleLiteral) %}
            when {{key.id.stringify}}
          {% else %}
            {% if key.is_a?(StringLiteral) %}
              when {{key}}
            {% elsif key.is_a?(NumberLiteral) || key.is_a?(BoolLiteral) %}
              when {{key.id}}
            {% elsif key.is_a?(Path) %}
              when {{key.resolve}}
            {% else %}
              {% key.raise "mapping keys must be one of StringLiteral, NumberLiteral, BoolLiteral, or Path, not #{key.class_name.id}" %}
            {% end %}
          {% end %}
          if pull.responds_to? :convention
            {{value.id}}.from_json(json, pull.convention)
          else
            {{value.id}}.from_json(json)
          end
        {% end %}
        else
          {% if default %}
          if pull.responds_to? :convention
            {{default}}.from_json(json, pull.convention)
          else
            {{default}}.from_json(json)
          end
          {% else %}
            raise ::JSON::SerializableError.new("Unknown '{{field.id}}' discriminator value: #{discriminator_value.inspect}", to_s, nil, *location, nil)
          {% end %}
        end
      end
    end

    macro use_json_discriminator(field, mapping, default = nil)
      caj_use_json_discriminator {{field}}, {{mapping}}, {{default}}
    end

    macro use_json_discriminator(field, mapping)
      caj_use_json_discriminator {{field}}, {{mapping}}
    end
    
  end
end

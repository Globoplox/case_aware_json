# JSON Converter to use to make a string attribute
# be case sensitive
module CaseAware
  extend self
  
  def from_json(parser : JSON::PullParser): String
    parser.read_object_key
  end
  
  def to_json(value, builder)
    if builder.responds_to? :format_key
      builder.format_key(value).to_json builder
    else
      value.to_json builder
    end
  end
end

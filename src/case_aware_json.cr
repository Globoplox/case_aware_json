require "json"
require "./discriminator"
require "./from_json"
require "./case_converter"

module CAJ
  extend self
  
  VERSION = {{ `shards version`.chomp.stringify }}
  
  enum Cases
    Snake
    Camel
    Pascal
    Kebab
  end
  
  class_property default_convention : Cases = Cases::Snake
  
  class PullParser < JSON::PullParser
    property convention : Cases
    
    def initialize(input, case _convention = CAJ.default_convention)
      super(input)
      @convention = _convention.is_a?(Cases) ? _convention : Cases.parse _convention.to_s
    end
    
    def read_object_key
      case @convention
      in Cases::Snake then read_string
      in Cases::Pascal, Cases::Camel
        read_string.underscore
          .gsub(/(?!^)(?<![0-9_])[0-9]+/) { |number| "_#{number}" }
          .gsub(/[0-9]+(?![0-9_])(?!$)/) { |number| "#{number}_" }
      in Cases::Kebab then read_string.gsub /\-/, '_'
      end
    end
  end
  
  class Builder < JSON::Builder
    property convention : Cases
    
    def initialize(io : IO, case _convention = CAJ.default_convention)
      super(io)
      @convention = _convention.is_a?(Cases) ? _convention : Cases.parse _convention.to_s
    end
    
    def format_key(key)
      case @convention
      in Cases::Snake then key
      in Cases::Camel then key.camelcase lower: true
      in Cases::Pascal then key.camelcase
      in Cases::Kebab then key.gsub /_/, '-'
      end
    end
    
    def field(name, value)
      super(format_key(name), value)
    end
    
    def field(name)
      super(format_key(name)) { yield }
    end
  end
  
end

class Object

  def to_json(case convention : CAJ::Cases | Symbol)
    String.build do |str|
      to_json str, convention
    end
  end

  def to_json(io : IO, case convention : CAJ::Cases | Symbol)
    JSON.build(io, convention) do |json|
      to_json(json)
    end
  end
  
end

module JSON

  def self.build(case convention : CAJ::Cases | Symbol, indent = nil)
    String.build do |str|
      build(str, convention, indent) do |json|
        yield json
      end
    end
  end

  def self.build(io : IO, case convention : CAJ::Cases | Symbol, indent = nil) : Nil
    builder = CAJ::Builder.new(io, convention)
    builder.indent = indent if indent
    builder.document do
      yield builder
    end
    io.flush
  end

end

def Object.from_json(string_or_io, case convention : CAJ::Cases | Symbol)
  parser = CAJ::PullParser.new(string_or_io, convention)
  new parser
end

def Object.from_json(string_or_io, root : String, case convention : CAJ::Cases | Symbol)
  parser = CAJ::PullParser.new(string_or_io, convention)
  parser.on_key!(root) do
    new parser
  end
end

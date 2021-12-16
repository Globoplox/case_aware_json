# Case Aware Json

Allow to serialize and deserialize json with various cases conventions for object keys.
Can be used by passing an extra param to the `to_json` and `from_json` methods.  
Might not mix well with `@[JSON::Field(key: "")]` annotations. The custom key will be transformed to and from the specified case.  
It works with `JSON::Serializable.use_json_discriminator` too.  
Also add an optional `default` parameter to `JSON::Serializable.use_json_discriminator` because it's handy and I need it anyway.  

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     case_aware_json:
       github: globoplox/case_aware_json
   ```

2. Run `shards install`

## Usage

```crystal
require "case_aware_json"

class Test
  include JSON::Serializable
  property test_property : String
  def initialize(@test_property) end
end

Test.new("test").to_json case: :camel
Test.from_json %({"testProperty": "test"}), case: :camel
```


## Contributors

- [Globoplox](https://github.com/globoplox) - creator and maintainer

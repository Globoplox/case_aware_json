require "./spec_helper"

class Test
  include JSON::Serializable
  property test_property : String
  def initialize(@test_property) end
end

class NestedTest
  include JSON::Serializable
  property nested_test : Test
  property many_nested_test = [] of Test
  def initialize(@nested_test)
    many_nested_test << @nested_test
  end
end

describe CAJ do

  it "can serialize to camelcase" do
    JSON.parse(Test.new("camel").to_json(case: CAJ::Cases::Camel))["testProperty"]?.should eq("camel")
  end

  it "can serialize to snakecase" do
    JSON.parse(Test.new("snake").to_json(case: CAJ::Cases::Snake))["test_property"]?.should eq("snake")
  end

  it "can serialize to pascalcase" do
    JSON.parse(Test.new("pascal").to_json(case: CAJ::Cases::Pascal))["TestProperty"]?.should eq("pascal")
  end
  
  it "can serialize to camelcase" do
    JSON.parse(Test.new("kebab").to_json(case: CAJ::Cases::Kebab))["test-property"]?.should eq("kebab")
  end

  it "can deserialize from camelcase" do
    Test.from_json(%({"testProperty": "camel"}), case: CAJ::Cases::Camel).test_property.should eq("camel")
  end

  it "can deserialize from snakecase" do
    Test.from_json(%({"test_property": "snake"}), case: CAJ::Cases::Snake).test_property.should eq("snake")
  end

  it "can deserialize from pascalcase" do
    Test.from_json(%({"TestProperty": "pascal"}), case: CAJ::Cases::Pascal).test_property.should eq("pascal")
  end

  it "can deserialize from kebabcase" do
    Test.from_json(%({"test-property": "kebab"}), case: CAJ::Cases::Kebab).test_property.should eq("kebab")
  end

  it "default serialization to snake" do
    JSON.parse(Test.new("snake").to_json)["test_property"]?.should eq("snake")
  end

  it "default deserilization to snake" do
    Test.from_json(%({"test_property": "snake"})).test_property.should eq("snake")
  end

  it "can serialize with symbol case param" do
    JSON.parse(Test.new("camel").to_json(case: :camel))["testProperty"]?.should eq("camel")
  end

  it "can deserilize with symbole case param" do
    Test.from_json(%({"testProperty": "camel"}), case: :camel).test_property.should eq("camel")
  end

  it "can serialize nested serilizable" do
    JSON.parse(NestedTest.new(Test.new("camel")).to_json(case: CAJ::Cases::Camel)).tap do |json|
      json["nestedTest"]?.try &.as_h?.try &.["testProperty"]?.should eq("camel")
      json["manyNestedTest"]?.try &.as_a?.try &.first?.try &.as_h?.try &.["testProperty"]?.should eq("camel")
    end
  end

  it "can deserialize nested serilizable" do
    Test.from_json(%({"test_property": "snake"}), case: CAJ::Cases::Snake).test_property.should eq("snake")
    NestedTest.from_json(%({"nestedTest": {"testProperty": "camel"}, "manyNestedTest": [{"testProperty": "camel"}]}), case: :camel).tap do |object|
      object.nested_test.test_property.should eq("camel")
      object.many_nested_test.first.test_property.should eq("camel")
    end
    
    JSON.parse(NestedTest.new(Test.new("camel")).to_json(case: CAJ::Cases::Camel)).tap do |json|
      json["nestedTest"]?.try &.as_h?.try &.["testProperty"]?.should eq("camel")
      json["manyNestedTest"]?.try &.as_a?.try &.first?.try &.as_h?.try &.["testProperty"]?.should eq("camel")
    end
  end

end

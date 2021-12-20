# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] 2020-12-20
### Feature
#### Fixed
- Support complex type unions

## [1.1.1] 2020-12-17
### Feature
#### Changed
- Method `CAJ::Biilder#format_key` is now public

## [1.1.0] 2020-12-16
### Feature
#### Added
- Add support of class using `JSON::Serializable.use_json_discriminator`.
- Add an optional default target type for `JSON::Serializable.use_json_discriminator`. 

## [1.0.0] 2020-12-02
### Feature
#### Added
- Allow to serialize/deserialize object keys as pascal, kebab, snake or camel case.

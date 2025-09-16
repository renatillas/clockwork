# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024

### 🎉 Major Release - Complete Refactor

This release represents a complete overhaul of the Clockwork library, bringing significant improvements to the API, documentation, and internal architecture.

### ✨ Added
- **Comprehensive Documentation**: Added detailed inline documentation for all public functions with examples and parameter descriptions
- **Improved Builder API**: Enhanced fluent API for building cron schedules programmatically
- **Better Type Safety**: Strengthened type definitions and error handling throughout the library
- **Extended README**: Completely rewrote the README with clear examples, feature descriptions, and usage patterns
- **CI/CD Improvements**: Added support for both Erlang 27 and 28 in GitHub Actions

### 🔄 Changed
- **Major API Refactor**: Simplified and streamlined the public API for better usability
- **Code Organization**: Removed separate `schedule.gleam` module and consolidated functionality
- **Dependency Updates**: Updated Gleam version to 1.11.1 and adjusted dependency version ranges for better compatibility
- **Function Naming**: Improved function names for clarity and consistency

### 🐛 Fixed
- **Bug Fix**: Fixed issue with `enqueue_job` being called multiple times when initializing actor
- **Compatibility**: Updated `gleam_stdlib` version range to be compatible with `gleam_erlang`
- **Documentation**: Fixed project name in README (was incorrect in previous version)
- **OTP Compatibility**: Updated to OTP v1 for stable operation

### 🔧 Technical Improvements
- **Code Quality**: Refactored internal implementation for better maintainability
- **Test Coverage**: Enhanced test suite with more comprehensive test cases
- **Performance**: Optimized cron expression parsing and validation
- **Error Messages**: Improved error reporting for invalid cron expressions

### 📦 Dependencies
- Updated to Gleam 1.11.1
- Compatible with gleam_stdlib >= 0.53.0 and < 2.0.0
- Compatible with gleam_time >= 1.0.0 and < 2.0.0

### 🚀 Migration Guide

Users upgrading from v1.x.x should note:
- The API has been significantly improved but some breaking changes exist
- Review the new README for updated usage examples
- The builder pattern remains similar but with enhanced functionality
- All cron field creation functions now have clearer names

## Previous Versions

### [1.1.0] - Previous Release
- Initial stable release with basic cron expression support
- Builder API for constructing cron schedules
- Basic parsing and validation functionality
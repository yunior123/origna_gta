#!/usr/bin/env ruby
# Script to add RunnerUITests target for Patrol integration testing
require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

# Check if RunnerUITests target already exists
if project.targets.any? { |t| t.name == 'RunnerUITests' }
  puts "✓ RunnerUITests target already exists — skipping"
  exit 0
end

# Get the Runner target to reference
runner_target = project.targets.find { |t| t.name == 'Runner' }
unless runner_target
  puts "✗ Runner target not found!"
  exit 1
end

# Create RunnerUITests target (UI Testing Bundle)
ui_test_target = project.new_target(
  :ui_testing_bundle,
  'RunnerUITests',
  :ios,
  '15.0'  # Match Runner's iOS deployment target
)

# Set the test target host
ui_test_target.add_dependency(runner_target)

# Create the file group
group = project.main_group.new_group('RunnerUITests', 'RunnerUITests')

# Add RunnerUITests.m to the project
ui_test_file_path = File.join(__dir__, 'RunnerUITests', 'RunnerUITests.m')
file_ref = group.new_file(ui_test_file_path)
ui_test_target.source_build_phase.add_file_reference(file_ref)

# Configure build settings for each configuration
ui_test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'ca.orignagta.app.RunnerUITests'
  config.build_settings['INFOPLIST_FILE'] = ''
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['TEST_TARGET_NAME'] = 'Runner'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@loader_path/Frameworks',
  ]
  # Disable user script sandboxing (required by Patrol)
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end

# Save
project.save
puts "✓ RunnerUITests target added successfully"

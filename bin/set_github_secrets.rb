#!/usr/bin/env ruby

require 'dotenv'
require 'open3'

# Load .env but don't pollute ENV
env_file = Dotenv.parse('.env')

def execute_command(cmd)
  stdout, status = Open3.capture2(cmd)
  stdout.strip if status.success?
end

puts "Setting GitHub secrets..."

env_file.each do |key, value|
  next if value.nil? || value.empty?

  if value.start_with?('$(') && value.end_with?(')')
    # Extract and execute command between $()
    cmd = value[2..-2]  # Remove $( and )
    actual_value = execute_command(cmd)
  else
    actual_value = value
  end

  next if actual_value.nil? || actual_value.empty?

  command = "gh secret set #{key} --body '#{actual_value}'"
  system(command, out: File::NULL)

  if $?.success?
    puts "✓ Successfully set #{key}"
  else
    puts "✗ Failed to set #{key}"
  end
end

puts "\nDone!"

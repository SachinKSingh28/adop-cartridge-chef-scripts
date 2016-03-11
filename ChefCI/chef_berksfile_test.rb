#!/usr/bin/env ruby
#
# Validate the cookbook's Berksfile
# -> No "local" dependencies allowed. (GIT only)
#

require 'berkshelf'
require 'chef/cookbook/metadata'

# Parse Metadata
metadata = Chef::Cookbook::Metadata.new
metadata.from_file 'metadata.rb'

# Parse Berksfile
berksfile = Berkshelf::Berksfile.from_file './Berksfile'
exit_code = 0

# Iterate all Berkshelf dependencies
berksfile.dependencies.each do |d|
  is_this_cb = ( d.name == metadata.name )
  is_path    = d.location.is_a? Berkshelf::PathLocation
  fail       = ( is_path && !is_this_cb )
  result_str = fail ? 'FAIL' : 'OK'
  puts "Dependency [#{d.name}] has location type [#{d.location.class}] - #{result_str}"
  exit_code += 1 if fail
end

# Quit with exit code (non-zero if we find a )
exit exit_code

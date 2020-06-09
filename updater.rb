#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'program'

# Update Manager
class UpdateManager
  def initialize
    @name = 'Update Manager'
    @config_filepath = File.join(__dir__, 'update_config.json')
  end

  def config
    JSON.parse(File.read(@config_filepath))
  end

  def update
    config.each do |program|
      next if program['disabled']

      updater = Program.new(program)
      updater.update
    end
  end
end

UpdateManager.new.update

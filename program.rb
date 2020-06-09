#!/usr/bin/env ruby
# frozen_string_literal: true

require 'uri'
require 'json'

require 'http'
require 'nokogiri'
require 'tty-logger'

require_relative 'programurl'

# class Program to update programs
class Program
  attr_reader :options

  def initialize(options)
    @options = options
    @log = TTY::Logger.new { |c| c.level = :debug }
  end

  def download_dir
    File.join(__dir__, @options['install']['downloadDir'])
  end

  def install_dir
    @options['install']['installDir']
  end

  def install_command
    @options['install']['commands']
  end

  def gsub_filename
    return '' unless @options['install'].key?('gsubFilename')

    @options['install']['gsubFilename']
  end

  def exec_cmd(command)
    p command
    `#{command}`
  end

  def download(url)
    @log.info 'Downloading', url
    command = "wget -N -c #{url} -P #{download_dir}"
    exec_cmd(command)
  end

  def metainfo(url)
    filename_ext = URI(url).path.split('/').last
    filename = File.basename(filename_ext, File.extname(filename_ext))
    filename.gsub!(gsub_filename, '') unless gsub_filename.empty?
    {
      downloadDir: download_dir,
      filename: filename,
      filename_ext: filename_ext,
      installDir: install_dir,
      url: url
    }
  end

  def extract(info)
    install_command.each do |command|
      exec_cmd(command % info)
    end
  end

  def update
    package_url = ProgramUrl.new(options).extract
    download(package_url)
    extract(metainfo(package_url))
  end
end

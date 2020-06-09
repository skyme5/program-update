#!/usr/bin/env ruby
# frozen_string_literal: true

require 'uri'
require 'json'

require 'http'
require 'nokogiri'
require 'tty-logger'
require 'natural_sort'

# class Program to update programs
class ProgramUrl
  def initialize(options)
    @options = options
    @log = TTY::Logger.new { |c| c.level = :debug }
  end

  def direct_url?
    @options['isURLDirect']
  end

  def url_css
    @options['selectors']['url']['css']
  end

  def url_regexp
    Regexp.new(@options['selectors']['url']['regexp'])
  end

  def url_select_last?
    @options['selectors']['url']['isLast']
  end

  def url
    @options['url']
  end

  def parse_url(url)
    @log.debug 'Download Webpage', url
    Nokogiri.HTML(HTTP.get(url).to_s)
  end

  def extract_url
    doc = parse_url(url)
    url_list =
      doc.css(url_css).to_a.map { |e| e['href'] }.sort(&NaturalSort)
         .select { |text| url_regexp.match(text) }
    p url_list
    url_select_last? ? url_list.last : url_list.first
  end

  def download_url
    if direct_url?
      url
    else
      link = extract_url
      link = URI.join(url, link) unless link.include?('http')
      link
    end
  end

  def extract
    package_url = download_url
    @log.info 'Package URL', package_url
    package_url
  end
end

require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'resque'
require 'manga-squirrel/worker'

module Manga
  module Squirrel
    class Manga::Squirrel::Downloader
      BASE_URL = "http://www.mangafox.com"
      
      def self.queue(series, options = {})
        chapters(series, options).each do |chapter_url|
          chapter = chapter(series, chapter_url)
      
          puts "QUEUE: #{chapter[:series]} volume #{chapter[:volume]} chapter #{chapter[:chapter]} pages 1-#{chapter[:pages]}..."
      
          1.upto(chapter[:pages]) do |page|
            page_url = chapter_url.gsub /(.*\/)(\d+)(.html)$/, "\\1#{page}\\3"
        
            Resque.enqueue(
              Manga::Squirrel::Worker,
              chapter[:series], chapter[:volume], chapter[:chapter], chapter[:caption], page, page_url
            )
          end
        end
      end
  
      private
  
      def self.chapters(series, options = {})
        url = "#{BASE_URL}/manga/#{series}"
    
        doc = Nokogiri::HTML(open(url))

        list = doc.css("table#listing td a.ch")
          .collect { |node| Manga::Squirrel::Downloader::BASE_URL + node.attribute('href').value }
          .reverse
          .select do |url|
            url =~ /http:\/\/.*?\/manga\/.*?\/v([0-9\.]+)\/c([0-9\.]+)\/\d+\.html/
            volume = $1.to_f
            chapter = $2.to_f
            
            volume_filter = eval(options[:volumes])
            volume_pass = case volume_filter.class.name
            when "Array", "Range"
              volume_filter.include?(volume)
            when "Fixnum", "Float"
              volume_filter == volume
            when "TrueClass", "FalseClass"
              volume_filter
            else
              true
            end
            
            chapter_filter = eval(options[:chapters])
            chapter_pass = case chapter_filter.class.name
            when "Array", "Range"
              chapter_filter.include?(chapter)
            when "Fixnum", "Float"
              chapter_filter == chapter
            when "TrueClass", "FalseClass"
              chapter_filter
            else
              true
            end
            
            volume_pass && chapter_pass
          end
      
      rescue Exception => e
        puts "ERROR: Could not get chapter list from Manga Fox."
      end
  
      def self.chapter(series, url)
        chapter = {}
    
        doc = Nokogiri::HTML(open(url))
    
        title = doc.css("meta[property='og:title']").attribute('content').value
        title =~ /(.*?) Manga Vol\.(\d+) Ch\.([0-9\.]+):? ?(.*)$/

        chapter[:series] = $1
        chapter[:volume] = $2
        chapter[:chapter] = $3
        chapter[:caption] = $4 || ''

        chapter[:pages] = doc.css("select.middle option[selected=selected]").first.parent.children.count
    
        chapter[:url] = url

        chapter
      end
    end
  end
end

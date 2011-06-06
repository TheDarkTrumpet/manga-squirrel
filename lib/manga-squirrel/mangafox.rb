require 'nokogiri'
require 'open-uri'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaFox
      BASE_URL = "http://www.mangafox.com"

      def self.getChapters(series, options)
        chapters = Array.new
        self.parseChapters(series, options).each {
          |chapter_url|
          chapters.pushself.parseChapter(series, chapter_url)
        }

        chapters
      end

      def self.getPageURL(chapter, page)
        chapter_url.gsub /(.*\/)(\d+)(.html)$/, "\\1#{page}\\3"
      end

      private
      def self.parseChapters(series, options)
        url = "#{BASE_URL}/manga/#{series}"
    
        doc = Nokogiri::HTML(open(url))

        list = doc.css("table#listing td a.ch").collect { |node| Manga::Squirrel::Downloader::BASE_URL + node.attribute('href').value }
        list.reverse!
        list.select do |url|
          url =~ /http:\/\/.*?\/manga\/.*?(\/v([0-9\.]+))?\/c([0-9\.]+)\/\d+\.html/
          volume = $2.to_f
          chapter = $3.to_f
          
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

      def self.parseChapter(series, url)
        chapter = {}
    
        doc = Nokogiri::HTML(open(url))
    
        title = doc.css("meta[property='og:title']").attribute('content').value
        title =~ /(.*?) Manga (Vol\.(\d+) )?Ch\.([0-9\.]+):? ?(.*)$/

        chapter[:series] = $1
        chapter[:volume] = $3
        chapter[:chapter] = $4
        chapter[:caption] = $5 || ''

        chapter[:pages] = doc.css("select.middle option[selected=selected]").first.parent.children.count
    
        chapter[:url] = url

        chapter
      end
    end
  end
end

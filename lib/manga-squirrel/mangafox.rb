require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'progressbar'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaFox
      BASE_URL = "http://www.mangafox.com"
      IMG_DIV = "image"
	  @@chapterlist = {}

      def self.getChapters(series, options, existingChapters)

        if @@chapterlist.include?(series) then
          return @@chapterlist[series]
        end

        chapters = Array.new

        tmp = self.parseChapters(series, options)
        pbar = ProgressBar.new(series, tmp.count)
        tmp.peach {
          |chapter_url|
          pbar.inc
          volume, chapter = self.parseURL(chapter_url)
          if existingChapters.include?(chapter) then
            next
          end
          chapters.push self.parseChapter(series, chapter_url)
        }
        pbar.finish

        @@chapterlist[series] = chapters

        chapters
      end

      def self.getPageURL(chapter, page)
        chapter[:url].gsub /(.*\/)(\d+)(.html)$/, "\\1#{page}\\3"
      end

      def self.urlify(series)
        series.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")
      end

      private
      def self.parseChapters(series, options)
        url = "#{BASE_URL}/manga/#{series}"
    
        doc = Nokogiri::HTML(open(url))

        list = doc.css("table#listing td a.ch").collect { |node| BASE_URL + node.attribute('href').value }
        list.reverse!
        
        volume_filter = eval(options[:volumes])
        chapter_filter = eval(options[:chapters])

        list.select do |url|
          volume, chapter = self.parseURL(url)

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

      def self.parseURL(url)
          url =~ /http:\/\/.*?\/manga\/.*?(\/v([X0-9\.]+))?\/c([0-9\.]+)\/\d+\.html/
          return $2.to_f, $3.to_f
      end

      def self.parseChapter(series, url)
        chapter = {}
    
        doc = Nokogiri::HTML(open(url))
    
        title = doc.css("meta[property='og:title']").attribute('content').value
        title =~ /(.*?) Manga (Vol\.([X0-9]+) )?Ch\.([0-9\.]+):? ?(.*)$/

        chapter[:series] = $1
        chapter[:volume] = $3
        chapter[:chapter] = $4
        chapter[:caption] = $5 || ''

        chapter[:pages] = doc.css("select.middle option[selected=selected]").first.parent.children.count
    
        chapter[:url] = url

        chapter[:img_div] = IMG_DIV

        chapter
      end
    end
  end
end

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'progressbar'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaReader
      BASE_URL = "http://www.mangareader.net"
	  @@chapterlist = {}

      def self.getChapters(series, options, existingChapters)
        if @@chapterlist.include?(series) then
          return @@chapterlist[series]
        end

        chapters = Array.new
        tmp = self.parseChapters(series, options)
        pbar = ProgressBar.new(series, tmp.count)
        #Change to peach once tested
        tmp.each {
          |v|
          pbar.inc
          chapter = self.getChapter(v)
          if existingChapters.include?(chapter) then
            next
          end
          chapters.push self.parseChapter(series, v)
        }
        pbar.finish

        @@chapterlist[series] = chapters

        chapters
      end

      def self.getPageURL(chapter, page)
        return BASE_URL + chapter[:pages_info][page]
      end

      def self.urlify(series)
        series.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")
      end

      private
      #Return hash key: series name, value:url
      def self.getSeriesURL(series)
        doc = Nokogiri::HTML(open(BASE_URL + "/alphabetical"))
        allSeriesDoc = doc.css('div[class^="series_col"]').to_s
        allSeries = {}
        allSeriesDoc.scan(/<li>$*<a href="([^"]*)">([^<]*)<\/a>/).each {
          |s|
          allSeries[self.urlify s[1]] = s[0]
        }
        allSeries[self.urlify series.strip]
      end

      #allChapters: array  0: url 1:series + number 2:title
      def self.parseChapters(series, options)
        url = self.getSeriesURL(series)
        doc = Nokogiri::HTML(open(BASE_URL + url))
        allChaptersDoc = doc.css('div[id^="chapterlist"]').to_s
        allChapters = allChaptersDoc.scan(/<a href="([^"]*)">([^<]*)<\/a> : ([^<]*)<\/td>/)
        
        chapter_filter = eval(options[:chapters])

        allChapters.select do |v|
          chapter = self.getChapter(v) 
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
          chapter_pass
        end

      rescue Exception => e
       puts "ERROR: Could not get the chapter list from Manga Reader."
      end

      def self.getChapter(v)
        (v[0].match /\/(.*)\/([0-9]*)/)[2].to_i
      end

      def self.parseChapter(series, v)
        chapter = {}

        doc = Nokogiri::HTML(open(BASE_URL + v[0]))
        
        chapter[:series] = series
        chapter[:volume] = nil
        chapter[:chapter] = self.getChapter(v)
        chapter[:caption] = v[2]
        

        pagesDoc = doc.css('select[id^="pageMenu"]').to_s
        pages = pagesDoc.scan(/<option value=\"([^']*?)\"[^>]*>\s*(\d*)<\/option>/)

        chapter[:pages] = pages.count
        chapter[:pages_info] = pages

        chapter[:url] = BASE_URL + v[0]

        chapter
      end
    end
  end
end
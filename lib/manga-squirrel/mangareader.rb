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
      end

      def self.getPageURL(chapter, page)
      end

      def self.urlify(series)
        series.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")
      end

      private
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

      def self.parseChapters(series, options)
      end

      def self.parseURL(url)
      end

      def self.parseChapter(series, url)
      end
    end
  end
end

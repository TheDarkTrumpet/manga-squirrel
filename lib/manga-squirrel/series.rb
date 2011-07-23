require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'progressbar'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::Series
      @base_url = "http;//www.[].com"
      @img_div = "#img" #Selecter for IMG 

      @chapter_list_css = ''
      @chapter_info_css = ''
      @chapter_info_regex = /(.*)/
      @pages_css = ''
      @pages_regex = /(.*)/

      @chapters = {}
      @series = ""

      def initialize(series)
        @series = series

        chapters
      end

      def chapters()
        if @chapters.nil?
          getChapters
        end

        @chapters
      end

      private
      #Must be overloaded with the actual site
      
      def urlify(str)
        str.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")
      end
      
      def getSeriesURL()
        #Very dependent on site
      end

      def getChapters()
        tmp = getChapterList
        pbar = ProgressBar.new(@series,tmp.count)
        tmp.peach {
          |url|
          pbar.inc
          @chapters.push getChapterInfo(url)
        }
        pbar.finish
      end

      def getChapterURLList(doc)
        #return array of urls
      end

      def getChapterList()
        url = getSeriesURL()

        doc = Nokogiri::HTML(open(url))
        getChapterURLList(doc.css(@chapter_list_css)).peach {
          |chapter_url|
          tmp = getChapterInfo(chapter_url)
        }
      end

      def getChapterInfoProcess(t)
        #multiple return (see below) based on results of regex in title
      end

      def getPageURL(page)
        #another site dependent bit
      end

      def getChapterInfo(url)
        chapter = {}

        doc = Nokogiri::HTML(open(url))
        title = doc.css(@chapter_info_css).attribute('content').value.scan(@chapter_info_regex)

        chapter[:series],chapter[:volume],chapter[:chapter],chapter[:caption] = getChapterInfoProcess(title)
        chapter[:url] = url

        chapter[:pages] = doc.css(@pages_css).to_s.scan(@pages_regex).map { |x| getPageURL(x[0]) }

        chapter
      end
    end
  end
end

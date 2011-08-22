require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'progressbar'
require 'peach'

module Manga
  module Squirrel
    module Series
      attr_accessor :existingChapters, :name, :root

      def initialize(options)
        @name = options[:name]
        @root = options[:root]

        @chapters = {}
        @existingChapters = []

        getExistingChapters
        chapters
      end

      def chapters
        if @chapters.count == 0
          getChapters
        end

        @chapters
      end

      private
      
      def urlify(str)
        str.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")
      end

      def getExistingChapters()
        Dir.glob(File.join(@root, @name, "*")).each do
          |chapter|
          @existingChapters.push revgendir(chapter)[:chapter].to_f
        end
      end
      
      def getChapters()
        tmp = getChapterList
        pbar = ProgressBar.new(@name,tmp.count)
        tmp.peach {
          |url|
          pbar.inc
          i = getChapterInfo(url)
          @chapters[i[:chapter]] = i
        }
        pbar.finish
      end

      def getChapterList()
        url = getSeriesURL()

        doc = Nokogiri::HTML(open(url))
        getChapterURLList(doc.css(self.class::CHAPTER_LIST_CSS)).peach {
          |chapter_url|
          tmp = getChapterInfo(chapter_url)
        }
      end

      def getChapterInfo(url)
        chapter = {}

        doc = Nokogiri::HTML(open(url))
        title = doc.css(self.class::CHAPTER_INFO_CSS).attribute('content').value.scan(self.class::CHAPTER_INFO_REGEX)[0]

        chapter[:series],chapter[:volume],chapter[:chapter],chapter[:caption] = getChapterInfoProcess(title)
        chapter[:url] = url

        chapter[:pages] = doc.css(self.class::PAGES_CSS).to_s.scan(self.class::PAGES_REGEX).map { |x| {:url=>getPageURL(chapter, x[0]), :num=>x[1]} }
        chapter[:img_div] = self.class::IMG_DIV
        
        chapter
      end
    end
  end
end

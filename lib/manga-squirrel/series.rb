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
        chapters unless options[:dontdownload]
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
        pbar = ProgressBar.new(@name,tmp.count) unless $isDaemon
        tmp.peach {
          |array|
          pbar.inc unless $isDaemon
          url = array[0]
          caption = array[1]

          i = getChapterInfo(url,caption)
          @chapters[i[:chapter]] = i
        }
        pbar.finish unless $isDaemon
      end

      def getChapterList()
        url = getSeriesURL()

        doc = Nokogiri::HTML(open(url))
        getChapterURLList(doc.css(self.class::CHAPTER_LIST_CSS))
      end

      def getChapterInfo(url, caption)
        chapter = {}

        doc = Nokogiri::HTML(open(url))
        title = doc.css(self.class::CHAPTER_INFO_CSS).attribute('content').value.scan(self.class::CHAPTER_INFO_REGEX)[0]

        chapter[:series],chapter[:volume],chapter[:chapter],otherCaption = getChapterInfoProcess(title)

        if caption.nil? then
          chapter[:caption] = otherCaption
        else
          chapter[:caption] = caption
        end if

        chapter[:url] = url

        chapter[:pages] = getPages(doc, chapter)
        chapter[:img_div] = self.class::IMG_DIV

        chapter
      end
    end
  end
end

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'progressbar'
require 'peach'
require 'base64'
require 'tmpdir'

module Manga
  module Squirrel
    module Series
      attr_accessor :existingChapters, :name, :root, :all

      def initialize(options)
        @name = options[:name]
        @root = options[:root]

        @chapters = {}
        @existingChapters = []
        @existingChapterInfo = {}

        getExistingChapters
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
          i = revgendir(chapter)
          @existingChapters.push i[:chapter]
          @existingChapterInfo[i[:chapter]] = i
        end
      end

      def getChapters()
        tmp = getChapterList
        encname = Base64.encode64 @name
        path = File.join(Dir.tmpdir, "ms.#{encname}")
        if File.exists? path then
          @chapters = YAML::load File.open(path,"r")
          return
        else
          pbar = ProgressBar.new(@name,tmp.count) unless $isDaemon
          tmp.each {
            |array|
            pbar.inc unless $isDaemon
            url = array[0]
            caption = array[1]
            num = getChapterNumberFromURL(url)

            if @existingChapters.include? num and not @all
              i = {:chapter=>num, :caption=>caption, :url=>url, :series=>@name, :volume=>@existingChapterInfo[num][:volume]}
            else
              i = getChapterInfo(url,caption)
            end

            @chapters[i[:chapter]] = i
          }
          File.open(path, "w") do
            |file|
            file.puts YAML::dump @chapters
          end
          pbar.finish unless $isDaemon
        end
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

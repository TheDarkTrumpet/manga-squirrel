require 'rubygems'
require 'fileutils'
require 'resque'
require 'manga-squirrel/common'
require 'manga-squirrel/downloadworker'
require 'manga-squirrel/bundleworker'

module Manga
  module Squirrel
    class Manga::Squirrel::Queuer
      def self.queueDownload(options)        
        seriesSan = site::urlify(options[:series])

        existingChapters = self.getExisting(options[:raw], options[:series])
        chapters = site::getChapters(seriesSan, options, existingChapters)

        if chapters.nil? then
          puts "ERROR: no chapters retrieved"
          return
        end

        dlChapters = []
        series.chapters.each_value do
          |chapter|
          if existingChapters.include?(chapter[:chapter])
            next
          end
          Resque.enqueue Manga::Squirrel::DownloadWorker, :chapter=>chapter,
                                                          :site=>site,
                                                          :raw=>options[:raw]
        end
      end

      def self.queueBundle(options)
        self.getExisting(options[:raw], options[:series]).each do
          |chapter|

          if File.size? genoutname(chapter, options[:cbf]) and not options[:force] then
            next
          end 

          Resque.enqueue Manga::Squirrel::BundleWorker, :chapter=>chapter, 
                                                        :raw=>options[:raw],
                                                        :out=>options[:out], 
                                                        :cbf=>options[:cbf]
        end
      end

      private
      def self.getExisting(raw, series)
        existingChapters = Array.new
        Dir.glob(File.join(raw, series,"*")).each do
          |chapter|
          existingChapters.push revgendir(chapter)[:chapter].to_f
        end
        existingChapters
      end
    end
  end
end

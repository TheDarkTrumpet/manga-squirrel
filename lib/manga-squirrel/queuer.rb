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

        s = options[:series].new :name=>options[:name], :root=>options[:raw]

        if s.chapters.nil? then
          puts "ERROR: no chapters retrieved"
          return
        end

        s.chapters.each_value do
          |chapter|
          if s.existingChapters.include?(chapter[:chapter])
            next
          end
          Resque.enqueue Manga::Squirrel::DownloadWorker, :chapter=>chapter,
                                                          :raw=>options[:raw]
        end
      end

      def self.queueBundle(options)
        s = options[:series].new :name=>options[:name], :root=>options[:raw]
        s.existingChapters.each do
          |chapter_number|

          chapter = s.chapters[chapter_number]
          chapter[:out] = options[:out]

          if File.size? ((gendir chapter[:out], chapter) + "." + options[:cbf]) and not options[:force] then
            next
          end

          Resque.enqueue Manga::Squirrel::BundleWorker, :chapter=>chapter,
                                                        :raw=>options[:raw],
                                                        :out=>options[:out],
                                                        :cbf=>options[:cbf]
        end
      end
    end
  end
end

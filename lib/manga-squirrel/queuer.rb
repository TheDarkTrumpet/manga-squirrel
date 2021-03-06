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

        begin
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

            $log.push chapter
          end
        rescue
          puts "Failed to finish downloading this series, unexpected error: #{$!}"
        end
      end

      def self.queueChapter(chapter, raw)
        Resque.enqueue Manga::Squirrel::DownloadWorker, :chapter=>chapter, :raw=>raw
      end

      def self.queueBundle(options)
        begin
          s = options[:series].new :name=>options[:name], :root=>options[:raw]
          s.existingChapters.each do
            |chapter_number|

            chapter = s.chapters[chapter_number]
            if chapter == nil
              next
            end
            chapter[:out] = options[:out]

            file = bundlePath chapter[:out], chapter, options[:cbf]

            if File.exists? file then
              if File.size(file) > 1024 and not options[:force] then
                next
              end
            end

            Resque.enqueue Manga::Squirrel::BundleWorker, :chapter=>chapter,
                                                          :raw=>options[:raw],
                                                          :out=>options[:out],
                                                          :cbf=>options[:cbf]
            $log.push chapter
          end
        rescue
            puts "Failed to finish bundling this series, unexpected error: #{$!}"
        end
      end
    end
  end
end

require 'rubygems'
require 'fileutils'
require 'resque'
require 'manga-squirrel/common'
require 'manga-squirrel/worker'

module Manga
  module Squirrel
    class Manga::Squirrel::Queuer
      def self.queue(action, options)
        case action
        when QueueAction::Download
          self.queueDownload options[:site], options[:series], options[:options]
        when QueueAction::Archive
          self.queueArchive options[:series], options[:options]
        end
      end

      private

      def self.getExisting(series)
        existingChapters = Array.new
        Dir.glob(File.join(series,"*")).each {
          |chapter|
          try = chapter.split(/(.*)\/([0-9]+)-([0-9.]+) (.*)/)[3]
          if try.nil? then
            try = chapter.split(/(.*)\/([0-9.]+) (.*)/)[2]
          end
          existingChapters.push try.to_f
        }
        existingChapters
      end

      def self.queueDownload(site, series, options)        
        seriesSan = site::urlify(series)

        existingChapters = self.getExisting(series)
        chapters = site::getChapters(seriesSan, options, existingChapters)

        if chapters.nil? then
          puts "ERROR: no chapters retrieved"
          return
        end

        chapters.each {
          |chapter|
          
          chapter[:root] = File.expand_path(".")
          path = gendir(chapter) 

          1.upto(chapter[:pages]) {
            |page|
            page_url = site::getPageURL(chapter, page)

            
            Resque.enqueue(
              Manga::Squirrel::Worker,
              QueueAction::Download, {:chapter=>chapter, :page=>page, :url=>page_url}
            )
          }
        }
      end

      def self.queueArchive(series, options)
        Dir.glob(File.join(series,"*")).each {
          |chapter|

          if File.exists? File.join(options[:out],series,chapter+".cbz") and not options[:force] then
                  next
          end 

          puts "QUEUE-CBZ: #{chapter}..."

          Resque.enqueue(
            Manga::Squirrel::Worker,
            QueueAction::Archive, {:root=>File.expand_path("."), :chapter=>chapter, :outdir=>options[:out]}
          )
        }
      end
    end
  end
end

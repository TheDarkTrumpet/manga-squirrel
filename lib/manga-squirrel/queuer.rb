require 'rubygems'
require 'fileutils'
require 'resque'
require 'progressbar'
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

      def self.queueDownload(site, series, options)        
        series = series.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")

        chapters = site::getChapters(series, options)

        if chapters.nil? then
          puts "ERROR: no chapters retrieved"
          return
        end

        pbar = ProgressBar.new(series, chapters.count)
        chapters.each {
          |chapter|
          path = gendir(chapter) 
          if File.directory? path then
            if Dir.glob(File.join(path,"*")).count == chapter[:pages] then
              next
            end
          end


          1.upto(chapter[:pages]) {
            |page|
            page_url = site::getPageURL(chapter, page)

            Resque.enqueue(
              Manga::Squirrel::Worker,
              QueueAction::Download, {:chapter=>chapter, :page=>page, :url=>page_url}
            )
          }
          pbar.inc
        }
        pbar.finish
      end

      def self.queueArchive(series, options)
        Dir.glob(File.join(series,"*")).each {
          |chapter|

          puts "QUEUE-CBZ: #{chapter}..."

          Resque.enqueue(
            Manga::Squirrel::Worker,
            QueueAction::Archive, {:chapter=>chapter, :outdir=>options[:outdir]}
          )
        }
      end
    end
  end
end

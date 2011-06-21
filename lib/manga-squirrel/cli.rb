require 'rubygems'
require 'thor'
require 'resque'
require 'manga-squirrel/common'
require 'manga-squirrel/queuer'

module Manga
  module Squirrel
    class CLI < Thor
      desc 'worker', 'Starts a manga-squirrel worker.'
      def worker
        worker = Resque::Worker.new('manga-squirrel')
        worker.verbose = true
        worker.log "Starting Worker #{worker}"

        worker.work(5)
      end

      desc 'workers [ --count=number ]', 'Starts a pool of manga-squirrel worker. The default number is 5.'
      method_option :count, :default => 5
      def workers
        threads = []

        options[:count].to_i.times do
          threads << Thread.new do
            system "manga-squirrel worker"
          end
        end

        threads.each { |thread| thread.join }    
      end

      desc 'cbz series [--out=dir]', 'Builds CBZs for all chapters for the specified series name'
      method_option :out, :default => "."
      def buildcbz(series)
        self.makequeue QueueAction::Archive, {:series=>series.strip, :optiens=>options}
      end

      desc 'queue series [--site=class --volumes=filter --chapters=filter]', 'Tries to fetch all chapters for given manga, skipping existing'
      method_option :site, :default => "MangaFox"
	  method_option :volumes, :default => "true"
	  method_option :chapters, :default => "true"
      def queue(series)
        site = ("Manga::Squirrel::"+options[:site]).to_class
        self.makequeue QueueAction::Download, {:site=>site,:series=>series,:options=>options}
      end

      desc 'fetch [--file=name --volumes=filter --chapters=filter]', 'Tries to fetch all mangas listed in filename, skipping any chapters already existing'
      method_option :file, :default => ".ms"
	  method_option :volumes, :default => "true"
	  method_option :chapters, :default => "true"
      def fetch
        begin
          f = File.open(options[:file], 'r')
        rescue
          puts "ERROR: File #{options[:file]} not found"
          return
        end
        f.readlines.each {
          |line|
		  splits = line.strip.split('	')
		  name = splits[0]
		  site = ("Manga::Squirrel::"+splits[1]).to_class
          puts "Fetching #{name} at #{site.inspect}"
          begin
            self.makequeue QueueAction::Download, {:site=>site,:series=>name,:options=>options}
          #rescue
          #  puts "ERROR: Failed to fetch #{name}\n#{$0} #{$.}: #{$!}"
          end
        }
        f.close
      end

      desc 'rename series', '**For upgrading between MS versions. Sanitizes all chapter names'
      def rename(series)
        Dir.glob(File.join(series,"*")).each {
          |chapter|
          if File.directory?(chapter) then
            new_name = Manga::Squirrel::Worker::namesanitize(chapter)
			unless new_name == chapter then
              puts "Renamed #{chapter} to #{new_name}"
              File.rename(chapter,new_name)
			end
          end
        }
      end

      no_tasks do
        def makequeue(action, options)
            Manga::Squirrel::Queuer.queue action, options
        end
      end
    end
  end
end

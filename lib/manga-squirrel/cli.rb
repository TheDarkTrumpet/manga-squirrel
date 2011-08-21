require 'rubygems'
require 'thor'
require 'resque'
require 'yaml'
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
      def cbz(series)
        self.makequeue QueueAction::Archive, {:series=>series.strip, :options=>{:out=>File.expand_path(options[:out])}}
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
      method_option :file, :default => "~/.ms"
      method_option :volumes, :default => "true"
      method_option :chapters, :default => "true"
      def fetch
        Manga::Squirrel::ConfigFile.parse(options[:file]).each do
          |name, site, raw, out, autocbz|
          puts "Fetching #{name]} from #{site}"
          begin
            self.makequeue QueueAction::Download, [:site=>site, :series=>name, :options=>options]
          rescue
            #  puts "ERROR: Failed to fetch #{name}\n#{$0} #{$.}: #{$!}"
          end
        end
        f.close
      end

      desc 'rename series [--perform=true]', '**For upgrading between MS versions. Sanitizes all chapter names'
      method_option :perform, :default => "false"
      def rename(series)
        Dir.glob(File.join(series,"*")).each {
          |chapter|
          if File.directory?(chapter) then
            new_name = chapter.sanitize
            unless new_name == chapter then
              puts "Renamed #{chapter} to #{new_name}"
              if eval(options[:perform]) then
                File.rename(chapter,new_name)
              end 
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

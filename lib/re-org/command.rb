require 'erb'
require 'fileutils'
require 'org-ruby'

module ReOrg
  class Command
    def initialize(options)
      @options = options
      @org = { }
      prepare_directories
    end

    def execute!
      case true
      when @options['setup']
        prepare_directories
      when @options['new']
        new_file
      when @options['notebook']
        reorganize_notebook
      when @options['status']
        show_status
      end
    end

    def show_status
      puts "============ CURRENT STATUS ============"
      org_files = Dir["#{@org[:path]}/current/*"]
      org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)
        if org_content.in_buffer_settings["NOTEBOOK"]
          puts "Writing for NOTEBOOK: #{org_content.in_buffer_settings["NOTEBOOK"]}".green
          puts org_content.headlines.first
        elsif not
          puts "Without a NOTEBOOK defined: #{org_file}".yellow
          puts org_content.headlines.first
        end
      end
    end

    def new_file
      @org[:current_dir] = current_dir
      @org[:time]     = Time.now
      @org[:title]    = @options["--title"] || 'Untitled'
      @org[:template] = @options["<template>"]
      @org[:notebook] = guess_notebook
      @org[:filename] = resolve_filename
      @org[:date]     = Time.at(@org[:time]).strftime("[%Y-%m-%d %a]")
      @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))

      c = 1
      while File.exists?(@org[:file])
        c += 1
        @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s-#{c}")
        @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))
      end
      template =  @org[:template] || 'writing'
      template_file = File.expand_path("templates/#{template}.org", File.dirname(__FILE__))
      if not File.exists?(template_file)
        puts "Could not find template `#{template}.org' at #{template_file}".red
        exit 1
      end
      template = File.open(template_file).read
      content = ERB.new(template).result(binding)

      File.open(@org[:file], 'w') {|f| f.puts content }
      puts content.yellow if ENV['DEBUG']
      puts "Created a new writing at `#{@org[:file]}'".green
    end

    def reorganize_notebook
      @org[:notebook] = guess_notebook
      path = File.expand_path("#{@org[:path]}/#{@org[:notebook]}")
      FileUtils.mkdir_p(path)

      # Fetch each one of the directories from the current folder
      org_files = Dir["#{@org[:path]}/current/*"]
      org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)

        # Put files with defined notebook in the right place
        if org_content.in_buffer_settings["NOTEBOOK"] == @org[:notebook]
          # Use the date of the file, otherwise use todays date
          date = org_content.in_buffer_settings["DATE"] || Time.now.strftime("%Y-%m-%d")
          date_dir = File.join(@org[:path], @org[:notebook], date)
          FileUtils.mkdir_p(date_dir)
          target_location = File.join(date_dir, File.basename(org_file))
          if not File.exists?(target_location)
            FileUtils.cp(org_file, target_location)
            puts "Copying `#{org_file}' to `#{target_location}'".green
          elsif @options["--force"]
            puts "Force copy on `#{target_location}'".yellow
          else
            puts "There is already an Org file at `#{target_location}'. Skipped.".yellow
          end
        elsif not org_content.in_buffer_settings["NOTEBOOK"]
          puts "Org file `#{org_file}' does not belong to any notebook.".yellow
        end
      end
    end

    private
    def slugify(name)
      return nil unless name
      name.gsub(/[\s.\/\\]/, '-').downcase
    end

    def guess_notebook
      @options["<notebook>"] || @options["--notebook"] || File.basename(File.expand_path('.'))
    end

    def resolve_filename
      slug = slugify(@org[:notebook] || @org[:title])
      Time.at(@org[:time]).strftime("#{slug}-%s")
    end

    def current_dir
      File.expand_path("#{@org[:path]}/current", File.dirname('.'))
    end

    def prepare_directories
      @org[:path] = File.expand_path(ENV['ORG_NOTEBOOKS_PATH'] || @options["--path"] || '.')
      if not File.exists?(current_dir)
        puts "Creating working dir at `#{current_dir}'".green
        FileUtils.mkdir(current_dir)
      end
    end
  end
end

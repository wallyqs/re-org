require 'erb'
require 'fileutils'
require 'org-ruby'

module ReOrg
  class Command
    def initialize(options)
      @options = options

      @org = { }
      @org[:time] = Time.now
      @org[:date] = Time.at(@org[:time]).strftime("%Y-%m-%d")
      @org[:org_format_date] = Time.at(@org[:time]).strftime("[%Y-%m-%d %a]")

      prepare_directories
    end

    def execute!
      case true
      when @options['setup']
        prepare_directories
      when @options['new']
        new_file
      when @options['update-notebook']
        reorganize_notebook
      when @options['compile-notebook']
        compile_notebook
      when @options['status']
        show_status
      end
    end

    def show_status
      puts "============ CURRENT STATUS ============"
      summary = Hash.new { |h,k| h[k] = [] }
      org_files = Dir["#{@org[:path]}/current/*"]
      org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)
        if org_content.in_buffer_settings["NOTEBOOK"]
          summary[org_content.in_buffer_settings["NOTEBOOK"]] << org_content
        else
          puts "Org file without notebook defined: #{org_file}".yellow
        end        
      end

      summary.each_pair do |notebook, orgs|
        puts "#{orgs.count} writings for '#{notebook}' notebook.".green
        orgs.each { |o| puts ["\t", o.headlines.first].join('')}
      end
    end

    def new_file
      @org[:current_dir] = current_dir
      @org[:title]    = @options["--title"] || 'Untitled'
      @org[:template] = @options["<template>"]
      @org[:notebook] = guess_notebook
      @org[:filename] = resolve_filename
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

      current_org_files = Dir["#{@org[:path]}/current/*"]
      current_org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)

        # Put files with defined notebook in the right place
        if org_content.in_buffer_settings["NOTEBOOK"] == @org[:notebook]
          # Use the date of the file, otherwise use todays date
          date = org_content.in_buffer_settings["DATE"] || @org[:date]
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

    def compile_notebook
      @org[:notebook] = guess_notebook
      @org[:title]    = @options["--title"] || 'Untitled'
      notebook_org_files = Dir["#{@org[:path]}/#{@org[:notebook]}/*/*"]
      if notebook_org_files.empty?
        puts "No notebook files were found for `#{@org[:notebook]}'.".red
        exit 1
      end
      full_org_file = []

      # FIXME: Ideally, OrgRuby should be able to do something as follows
      # to remove unwanted export features like COMMENT headlines:
      # files.each { |o| Orgmode::Parser.new(File.open(o).read); content += o.to_org }
      notebook_org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)
        org_content.headlines.each do |h|
          full_org_file << h.body_lines
        end
      end

      full_org_file_path = File.join(@org[:path], @org[:notebook], "#{@org[:notebook]}.org")
      if File.exists?(full_org_file_path) and not @options['--force']
        puts "Org file `#{full_org_file_path}' already exists. Use --force to overwrite.".red
        exit 1
      elsif @options['--force']
        c = 1
        backup_file = "#{full_org_file_path}.#{c}"
        while File.exists?(backup_file)
          backup_file = "#{full_org_file_path}.#{c}"
          c += 1
        end
        puts "Saving backup of already compiled Org file at `#{backup_file}'".yellow
        FileUtils.mv(full_org_file_path, backup_file)
      end

      template_file = File.expand_path("templates/notebook.org", File.dirname(__FILE__))
      if not File.exists?(template_file)
        puts "Could not find template `#{template}.org' at #{template_file}".red
        exit 1
      end
      template = File.open(template_file).read
      content = ERB.new(template).result(binding)

      # At the headers first from the template
      File.open(full_org_file_path, 'a') { |f| f.puts content }

      # Merge all the headlines into the file
      full_org_file.flatten.each do |h|
        File.open(full_org_file_path, 'a') { |f| f.puts h }
      end
      puts "Compiled Org file `#{full_org_file_path}'".green
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

require 'erb'
require 'fileutils'
require 'org-ruby'

module ReOrg

  class Command

    CUSTOM_TEMPLATES_DIRS = ['templates', '_templates']

    def initialize(options)
      @options = options
    end

    def execute!
      case true
      when @options['new']
        new_file
      when @options['status']
        show_status
      when (@options['templates'] and not @options['--name'].nil?)
        cat_template
      when @options['templates']
        show_templates
      end
    end

    def show_status
      puts '* Current Status'.yellow
      puts ''
      summary = Hash.new { |h,k| h[k] = {} }

      org_files = Dir["#{OrgFile.todo_dir}/*"]
      org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)
        if org_content.in_buffer_settings["NOTEBOOK"]
          notebook_name = org_content.in_buffer_settings["NOTEBOOK"]
          summary[notebook_name][:texts]    ||= []
          summary[notebook_name][:keywords] ||= {}
          summary[notebook_name][:texts] << org_content
          keywords = org_content.headlines.map { |h| h.keyword }
          keywords.each do |k|
            summary[notebook_name][:keywords][k] ||= 0
            summary[notebook_name][:keywords][k]  += 1
          end
        else
          puts "Org file without notebook defined: #{org_file}".yellow
        end
      end

      summary.each_pair do |notebook, info|
        puts "- #{info[:texts].count} org files for '#{notebook}' notebook".green
        info[:keywords].each do |keyword, count|
          keyword ||= 'NONE'
          puts "#{keyword}: #{count}"
        end if @options["--count-keywords"]
        info[:texts].each { |o| puts ["\t", o.headlines.first].join('')}
      end
    end

    def show_templates
      puts '* Default Templates'.yellow
      puts ''
      default_template_dir = File.expand_path("templates/", File.dirname(__FILE__))
      default_templates = Dir["#{default_template_dir}/*"]
      default_templates.each do |template|
        puts "- #{File.basename(template)}\t(default)"
      end

      CUSTOM_TEMPLATES_DIRS.each do |template_dir|
        if Dir.exists?(template_dir)
          Dir["#{template_dir}/*"].each do |template|
            puts "- #{File.basename(template)}\t(found at #{template_dir}/)"
          end
        end
      end
    end

    def cat_template
      default_template_dir = File.expand_path("templates/", File.dirname(__FILE__))
      default_templates = Dir["#{default_template_dir}/*"]
      template_name = default_templates.select { |path| File.basename(path) == @options['--name']}
      puts File.open(template_name.first).read
    rescue => e
      puts "Could not fetch template '#{@options['--name']}'".red
    end

    def new_file
      @org = OrgFile.new({ :title => @options["--title"],
                           :template => @options["<template>"],
                           :notebook => @options["<notebook>"] || @options["--notebook"],
                           :path     => @options["--path"]
                         })
      OrgFile.prepare_directories(@org) unless @options["--path"]

      c = 1
      while File.exists?(@org[:file])
        c += 1
        @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s-#{c}")
        @org[:file]     = File.expand_path(File.join(@org[:todo_dir], "#{@org[:filename]}.org"))
      end
      template =  @org[:template] || 'writing'
      template_file = find_template(template)
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

    private
    def find_template(template)
      CUSTOM_TEMPLATES_DIRS.each do |template_dir|
        if Dir.exists?(template_dir) and File.exists?(File.join(template_dir, "#{template}.org"))
          return File.expand_path(File.join(template_dir, "#{template}.org"))
        end
      end

      return File.expand_path(File.join('templates', "#{template}.org"), File.dirname(__FILE__))
    end
  end
end

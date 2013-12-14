module ReOrg
  class OrgFile

    attr_accessor :options

    DEFAULT_TODO_ORGS_DIR = 'todo'
    DEFAULT_DONE_ORGS_DIR = 'done'

    def initialize(opts={})
      @options = opts

      @options[:title]         ||= 'Untitled'
      @options[:time]            = Time.now
      @options[:date]            = Time.at(@options[:time]).strftime("%Y-%m-%d")
      @options[:org_format_date] = org_format_date(@options[:time])
      @options[:todo_dir]      ||= @options[:path] || OrgFile.todo_dir
      @options[:done_dir]      ||= OrgFile.done_dir
      @options[:notebook]      ||= File.basename(File.expand_path('.'))
      @options[:filename]        = resolve_filename
      @options[:file]            = File.expand_path(File.join(@options[:todo_dir], "#{@options[:filename]}.org"))
    end

    def []=(key, value)
      @options[key] = value
    end

    def [](key)
      @options[key]
    end

    def org_format_date(time=nil)
      time ||= @options[:time]
      Time.at(time).strftime("[%Y-%m-%d %a]")
    end

    def resolve_filename
      slug = slugify(@options[:title] || @options[:notebook])
      Time.at(@options[:time]).strftime("%Y-%m-%d-#{slug}")
    end

    def slugify(name)
      return nil unless name
      name.gsub(/[\s.\/\\]/, '-').downcase
    end

    def self.prepare_directories(org={})
      todo_dir = org[:path] || OrgFile.todo_dir
      if not File.exists?(todo_dir)
        puts "Creating working dir at `#{todo_dir}'".green
        FileUtils.mkdir(todo_dir)
      end
    end

    def self.path
      File.expand_path(ENV['ORG_NOTEBOOKS_PATH'] || '.')
    end

    # FIXME: There should be a todo dir and a done dir?
    def self.todo_dir
      # Detect that we are on a Jekyll site and use _drafts
      if File.exists?(File.expand_path('_config.yml', File.dirname('.'))) \
        and Dir.exists?('_drafts')
        File.expand_path('_drafts', File.dirname('.'))
      else
        File.expand_path("#{self.path}/#{DEFAULT_TODO_ORGS_DIR}", File.dirname('.'))
      end
    end

    def self.done_dir
      # Detect that we are on a Jekyll site and use _posts
      if File.exists?(File.expand_path('_config.yml', File.dirname('.'))) \
        and Dir.exists?('_posts')
        File.expand_path('_posts', File.dirname('.'))
      else
        File.expand_path("#{self.path}/#{DEFAULT_DONE_ORGS_DIR}", File.dirname('.'))
      end
    end
  end
end

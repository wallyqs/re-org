require 're-org'
require 'fileutils'

CURRENT_DIR = File.expand_path('./results', File.dirname(__FILE__))
FileUtils.mkdir_p(CURRENT_DIR)
ENV['ORG_NOTEBOOKS_PATH'] = CURRENT_DIR

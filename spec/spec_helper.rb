require 're-org'
require 'fileutils'

RESULTS_DIR = File.expand_path('./results', File.dirname(__FILE__))
FileUtils.mkdir_p(RESULTS_DIR)
ENV['ORG_NOTEBOOKS_PATH'] = RESULTS_DIR

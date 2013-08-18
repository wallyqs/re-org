require 'spec_helper'

describe ReOrg::Command do
  let(:cmd) do
    {
      "new"        => false,
      "<template>" => nil,
      "--notebook" => nil,
      "--path"     => nil,
      "--title"    => nil,
      "setup"      => false,
      "status"     => false,
      "update"     => false,
      "--force"    => false,
      "compile"    => false,
      "publish"    => false,
      "--help"     => false,
      "--version"  => false
    }
  end

  before(:each) do
    FileUtils.mkdir_p("#{RESULTS_DIR}/current")
  end

  after(:each) do
    `rm -rf #{RESULTS_DIR}/*`
  end

  context "when using `re-org new`" do 
    before(:each) do
      @cmd = {
        "new"        => true,
        "<template>" => 'writing',
        "--notebook" => nil,
        "--path"     => nil,
        "--title"    => nil,
      }
    end    

    it 'should create new writing for a notebook with --notebook option' do
      @cmd['--notebook'] = 'tests'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{RESULTS_DIR}/*"]
      orgs.count.should == 1
    end

    it 'should create new clockfile when the template is choosen' do
      @cmd['<template>'] = 'clockfile'
      @cmd['--notebook'] = 'tests'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{RESULTS_DIR}/*"]
      orgs.count.should == 1
    end

    it 'should create new writing with --title option' do
      @cmd['--notebook'] = 'tests'
      @cmd['--title']    = 'Testing the title'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{RESULTS_DIR}/*"]
      orgs.count.should == 1
    end
  end

  context "when using `re-org setup`" do 
    it 'should setup the directories'
  end

  context "when using `re-org update`" do
    it 'should update a notebook folder from the contents of current/'
  end

  context "when using `re-org publish`" do
    it 'should publish the contents from a notebook'
  end

  context "when using `re-org compile`" do
    it 'should compile the contents from a notebook into a single file'
  end
end

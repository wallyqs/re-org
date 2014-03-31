require 'spec_helper'

describe ReOrg::Command do
  before(:all)  { $test_number = 0 }
  before(:each) { 
    @dir = "#{RESULTS_DIR}/#{$test_number}"
    FileUtils.mkdir_p(@dir)
    ENV['ORG_NOTEBOOKS_PATH'] = @dir
  }
  after(:each)  { $test_number += 1 }

  context "when using `re-org new`" do
    before(:each) do
      @cmd = {
        "new"        => true,
        "<template>" => 'writing',
        "--notebook" => nil,
        "--title"    => "test-#{$test_number}",
      }
    end

    it 'should create new writing for a notebook with --notebook option' do
      @cmd['--notebook'] = 'tests'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
    end

    it 'should create new clockfile when the template is choosen' do
      @cmd['<template>'] = 'clockfile'
      @cmd['--notebook'] = 'tests'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
    end

    it 'should create new writing with --title option' do
      @cmd['--notebook'] = 'tests'
      @cmd['--title']    = 'Testing the title'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
    end
  end

  context "when using `re-org new jekyll-post`" do
    before(:each) do
      @cmd = {
        "new"        => true,
        "<template>" => 'jekyll-post',
        "--title"    => "test-#{$test_number}",
      }
    end

    it 'should create a new jekyll-post with the --title option' do
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
    end

    it 'should create a new jekyll-post with an arbitrary date given the --date option' do
      @cmd['--date']    = '2014-03-29'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
      orgs.first.should =~ /2014-03-29/
    end

    it 'should create a new jekyll-post with a layout set by --layout option' do
      @cmd['--layout']    = 'main'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
      File.open(orgs.first).read().should =~ /\#\+layout\:        main/
    end

    it 'should create a new jekyll-post with a category set by --category option' do
      @cmd['--category']    = 'food'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{@dir}/todo/*"]
      orgs.count.should == 1
      File.open(orgs.first).read().should =~ /\#\+category\:      food/
    end
  end

  context "when using `re-org templates`" do 
    before(:each) do
      @cmd = {
        "templates"   => true
      }
    end

    it 'should display the currently installed templates' do
      pending
      o = ReOrg::Command.new(@cmd)
      o.execute!
    end
  end
end

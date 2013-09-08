require 'spec_helper'

describe ReOrg::Command do
  before(:each) { FileUtils.mkdir_p("#{RESULTS_DIR}/current") }

  # Clean up after tests are done
  after(:each)  { `rm -rf #{RESULTS_DIR}` }

  context "when using `re-org new`" do 
    before(:all) do
      @test_number = 0
    end

    before(:each) do
      @cmd = {
        "new"        => true,
        "<template>" => 'writing',
        "--notebook" => nil,
        "--title"    => "test-#{@test_number}",
      }
      @test_number += 1
    end

    it 'should create new writing for a notebook with --notebook option' do
      @cmd['--notebook'] = 'tests'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{RESULTS_DIR}/todo/*"]
      orgs.count.should == 1
    end

    it 'should create new clockfile when the template is choosen' do
      @cmd['<template>'] = 'clockfile'
      @cmd['--notebook'] = 'tests'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{RESULTS_DIR}/todo/*"]
      orgs.count.should == 1
    end

    it 'should create new writing with --title option' do
      @cmd['--notebook'] = 'tests'
      @cmd['--title']    = 'Testing the title'
      o = ReOrg::Command.new(@cmd)
      o.execute!
      orgs = Dir["#{RESULTS_DIR}/todo/*"]
      orgs.count.should == 1
    end
  end
end

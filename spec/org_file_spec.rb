require 'spec_helper'
require 'time'

describe ReOrg::OrgFile do
  before(:each) do
    @org = ReOrg::OrgFile.new
  end

  it 'should create date in org format' do
    date = Time.at(1377411362).utc
    @org.org_format_date(date).should == '[2013-08-25 Sun]'
  end
end

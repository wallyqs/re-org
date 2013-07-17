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

  it 'should create new writing with notebook and title' do
    cmd['new']        = true
    cmd['--notebook'] = 'new-notebook'
    cmd['--title']    = 'a new title'
    o = ReOrg::Command.new(cmd)
    o.execute!
    orgs = Dir["#{CURRENT_DIR}/*"]
    orgs.count.should > 0
  end

  it 'should setup the directories'
  it 'should update a notebook folder from the contents of current/'
  it 'should publish the contents from a notebook'
  it 'should compile the contents from a notebook into a single file'
end

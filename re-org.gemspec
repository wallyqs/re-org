# -*- encoding: utf-8 -*-
require File.expand_path('../lib/re-org/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Waldemar Quevedo"]
  gem.email         = ["waldemar.quevedo@gmail.com"]
  gem.description   = %q{An Org mode file organizer}
  gem.summary       = %q{Instead of having tons of sparsed Org mode files everywhere, this project attemtps to give the Org mode writer a framework to re-organize the files in a less chaotic manner.
}
  gem.homepage      = "https://github.com/wallyqs/re-org"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "re-org"
  gem.require_paths = ["lib"]
  gem.version       = ReOrg::VERSION
  gem.add_dependency(%q<docopt>)
end

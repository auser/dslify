# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dslify}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ari Lerner"]
  s.date = %q{2009-01-27}
  s.description = %q{Easily add DSL-like calls to any class}
  s.email = ["arilerner@mac.com"]
  s.files = ["test/test_dslify.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://dslify.rubyforge.org}
  s.post_install_message = %q{Thanks for installing dslify!

For more information on dslify, see http://dslify.rubyforge.org

Ari Lerner}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dslify}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Easily add DSL-like calls to any class}
  s.test_files = ["test/test_dslify.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
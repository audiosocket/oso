require "hoe"

Hoe.plugin :doofus, :git

Hoe.spec "oso" do
  developer "Audiosocket", "it@audiosocket.com"

  self.extra_rdoc_files = Dir["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"
  self.testlib          = :minitest

  extra_dev_deps << ["fakeweb",  "1.3.0"]
  extra_dev_deps << ["minitest", "2.0.2"]
  extra_dev_deps << ["mocha",    "0.9.12"]
end

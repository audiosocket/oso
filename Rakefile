require "isolate/now"
require "hoe"

Hoe.plugin :doofus, :git

Hoe.spec "oso" do
  developer "Audiosocket", "it@audiosocket.com"

  self.extra_rdoc_files = Dir["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"
  self.testlib          = :minitest
end

desc "Run rackup using Isolate for deps."
task :rackup do
  sh "rackup"
end

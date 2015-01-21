desc "Deploy new version to Heroku"
task :deploy do
  # deploy
  success = system "git push heroku HEAD:master"
  if not success
    abort "Deploy failed."
  end

  # get new version number
  ver = `heroku releases`.split("\n")[1].split(" ")[0]
  hash = `git rev-parse HEAD`.strip
  tag_name = "heroku/#{ver}"

  # tag and push new tag
  system "git tag -a -m \"Deploy #{hash}\" #{tag_name} #{hash}"
  system "git push origin #{tag}"
end

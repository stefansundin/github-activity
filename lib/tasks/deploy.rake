desc "Deploy new version to Heroku"
task :deploy do
  success = system "git push heroku HEAD:master"
  if not success
    abort "Deploy failed."
  end
  Rake.application.invoke_task("deploy:tag")
end

namespace :deploy do
  desc "Forcibly deploy new version to Heroku"
  task :force do
    success = system "git push heroku HEAD:master --force"
    if not success
      abort "Deploy failed."
    end
    Rake.application.invoke_task("deploy:tag")
  end

  desc "Tag latest release"
  task :tag do
    # get heroku version number
    ver = `heroku releases`.split("\n")[1].split(" ")[0]
    hash = `git rev-parse HEAD`.strip
    tag_name = "heroku/#{ver}"

    # tag and push new tag
    success = system "git tag -a -m \"Deploy #{hash}\" #{tag_name} #{hash}"
    abort if not success
    system "git push origin #{tag_name}"
  end
end

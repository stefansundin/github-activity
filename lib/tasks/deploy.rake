require 'shellwords'

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

    # build tag message
    last_tag = `git describe --tags --abbrev=0 --match 'heroku/v*'`.strip
    commits = `git log #{last_tag}..HEAD --pretty=format:"- [%s](https://github.com/stefansundin/github-activity/commit/%H)"`
    message = "Deploy #{hash}\n\n#{commits}"

    # tag and push new tag
    success = system "git tag -a -m \"#{Shellwords.escape(message)}\" #{tag_name} #{hash}"
    abort if not success
    system "git push origin #{tag_name}"
  end
end

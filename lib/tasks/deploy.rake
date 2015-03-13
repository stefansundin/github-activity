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
    hash = `git rev-parse --short HEAD`.strip
    tag_name = "heroku/#{ver}"

    # build tag message
    last_tag = `git describe --tags --abbrev=0 --match 'heroku/v*'`.strip
    commits = `git log #{last_tag}..#{hash} --pretty=format:"- [%s](https://github.com/stefansundin/github-activity/commit/%H)"`
    message = "Deploy #{hash[0..6]}\n\nDiff: https://github.com/stefansundin/github-activity/compare/#{last_tag}...#{tag_name}\n#{commits}"

    # tag and push new tag
    success = system "git tag -a -m \"#{message.gsub('"','\\"')}\" #{tag_name} #{hash}"
    abort if not success
    system "git push origin #{tag_name}"
  end
end

desc "Rebuild all the release tags"
task :retag do
  tags = `git tag -l heroku/v* --sort=version:refname`.split("\n")

  tags.each_with_index do |tag, i|
    last_tag = if i == 0
      `git rev-list --max-parents=0 HEAD`.strip
    else
      tags[i-1]
    end

    hash = `git rev-list --max-count=1 #{tag}`.strip
    date = `git show --pretty="format:%ai" -s --no-color #{tag} | tail -1`.strip
    commits = `git log #{last_tag}..#{tag} --pretty=format:"- [%s](https://github.com/stefansundin/github-activity/commit/%H)"`
    message = "Deploy #{hash[0..6]}\n\nDiff: https://github.com/stefansundin/github-activity/compare/#{last_tag}...#{tag}\n#{commits}"

    if i == 0
      message += "\n"+`git show #{last_tag} -s --pretty=format:"- [%s](https://github.com/stefansundin/github-activity/commit/%H)"`
    end

    success = system "GIT_COMMITTER_DATE='#{date}' git tag -f -a -m \"#{message.gsub('"','\\"')}\" #{tag} #{tag}^{}"
    abort if not success
  end

  puts "Done"
end

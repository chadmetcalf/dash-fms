require 'octokit'

SCHEDULER.every '1m', :first_in => 0 do |job|
  client = Octokit::Client.new(:access_token => ENV['GITHUB_AUTH_TOKEN'])
  my_organization = ENV['GITHUB_ORGANIZATION_NAME']
  repo = ENV['GITHUB_REPO_NAME']

  open_pull_requests = []
  client.pull_requests("#{my_organization}/#{repo}", :state => 'open').each do |pull|
    open_pull_requests.push({
      title: pull.title,
      repo: repo,
      updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
      creator: "@" + pull.user.login,
      })
  end

  send_event('github-pr', { header: "Open Pull Requests",
                            pulls: open_pull_requests.sort_by { |pr| pr[:updated_at] }.reverse })
end

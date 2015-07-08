require 'octokit'

def client
  Octokit::Client.new(:access_token => ENV['GITHUB_AUTH_TOKEN'])
end

def organization_name
  ENV['GITHUB_ORGANIZATION_NAME']
end

def repo_name
  ENV['GITHUB_REPO_NAME']
end

def open_pull_requests
  # TODO: Label: Needs review
  client.pull_requests("#{organization_name}/#{repo_name}", :state => 'open')
end

SCHEDULER.every( '5m', { first_in: '5s', allow_overlapping: false }) do |job|
  most_recent_open_prs = open_pull_requests.map do |pull|
    { title: pull.title,
      repo_name: repo_name,
      updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
      creator: "@" + pull.try(:user).try(:login)
    }
  end
  open_prs = most_recent_open_prs.sort_by { |pr| pr[:updated_at] }.reverse.first(4)

  send_event('github-prs', { total: open_pull_requests.length, pulls: open_prs })
end

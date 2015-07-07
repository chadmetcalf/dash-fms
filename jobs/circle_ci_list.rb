require 'httparty'
require 'digest/md5'

projects = [
  { user: ENV['CIRCLECI_USER'], repo: ENV['CIRCLECI_REPO'], branch: 'master' }
]

def translate_status_to_class(status)
  statuses = {
    'success' => 'passed',
      'fixed' => 'passed',
    'running' => 'pending',
     'failed' => 'failed'
  }
  statuses[status] || 'pending'
end

def update_builds(project, auth_token)
  api_url = 'https://circleci.com/api/v1/project/%s/%s/tree/%s?circle-token=%s'
  api_url = api_url % [project[:user], project[:repo], project[:branch], auth_token]
  api_response =  HTTParty.get(api_url, :headers => { "Accept" => "application/json" } )
  api_json = JSON.parse(api_response.body)
  return {} if api_json.empty?

  builds = api_json.select{ |build| build['status'] != 'queued' }.first(6)

  builds.map do |build|
    {
      repo: "#{project[:repo]}",
      branch: "#{build['branch']}",
      widget_class: "#{translate_status_to_class(build['status'])}",
      avatar_url: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(build['committer_email'])}",
      title: "Build ##{build['build_num'].to_s}",
      subject: build['subject'],
      committer: build['committer_name'],
      state: build['status']
    }
  end
end

SCHEDULER.every '10m', :first_in => 3  do
  items = projects.map{ |p| update_builds(p, ENV['CIRCLECI_API_TOKEN']) }.flatten
  send_event('circle-ci-list', { items: items })
end

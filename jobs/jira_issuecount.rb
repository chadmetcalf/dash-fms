require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'

JIRA_OPENISSUES_CONFIG = {
  jira_url: 'https://jira.rnl.io',
  project: 'FMS',
  username: ENV['JIRA_USERNAME'],
  password: ENV['JIRA_PASSWORD'],
  issuecount_mapping: {
    'to-do':    'To Do',
    'analyze':  'Analyze',
    'rejected': 'Rejected',
    'staging rejected': 'Staging Rejected',
    'needs changes': 'Needs Changes',
    'dev-in-progress': 'In Progress',
    'demo': 'Demo',
    'pull-request': 'Pull Request',
    'qa-ready': 'QA Ready',
    'qa-in-progress': 'QA in Progress',
    'staging-ready': 'Staging Ready',
    'on-staging': 'On Staging',
    'staging-qa': 'Staging QA In Progress',
    'accepted-for-release': 'Accepted for Release'
  }
}

def getNumberOfIssues(url, username, password, jqlStatus)
  uri = URI.parse("#{url}/rest/api/2/search?jql=project%20%3D%20FMS%20AND%20Sprint%20in%20openSprints()%20AND%20status%20%3D%20%22#{jqlStatus}%22")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)

  request.basic_auth(ENV['JIRA_USERNAME'], ENV['JIRA_PASSWORD'])

  JSON.parse(http.request(request).body)["total"]
end

JIRA_OPENISSUES_CONFIG[:issuecount_mapping].each do |mappingName, filter|
  SCHEDULER.every '10m', :first_in => 0 do
    issues = case filter
    when /rejected/i
      ['Rejected','Staging+Rejected','Needs+Changes'].map do |status|
        getNumberOfIssues(JIRA_OPENISSUES_CONFIG[:jira_url], JIRA_OPENISSUES_CONFIG[:username], JIRA_OPENISSUES_CONFIG[:password], status)
      end
    else
      [ getNumberOfIssues(JIRA_OPENISSUES_CONFIG[:jira_url], JIRA_OPENISSUES_CONFIG[:username], JIRA_OPENISSUES_CONFIG[:password], filter) ]
    end

    total = issues.reduce(:+)
    send_event(mappingName, {current: total})
  end
end

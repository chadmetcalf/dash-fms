require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'

require 'dotenv'
Dotenv.load unless ENV['JIRA_USERNAME']


JIRA_CONFIG = {
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

def number_of_issues(status)
  jira_response_body(status)["total"]
end

def sum_of_points(status)
  jira_response_body(status)["issues"].map do |issue|
    issue['fields']['customfield_10005'].to_i || 0
  end.compact.reduce(:+)
end

def jira_response_body(status)
  if @jira_response_body && @jira_status && (@jira_status == status)
    return @jira_response_body
  end


  uri = URI.parse("#{JIRA_CONFIG[:jira_url]}/rest/api/2/search?jql=project%20%3D%20FMS%20AND%20Sprint%20in%20openSprints()%20AND%20status%20%3D%20%22#{status}%22")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)

  request.basic_auth(JIRA_CONFIG[:username], JIRA_CONFIG[:password])
  @jira_response_body = JSON.parse(http.request(request).body)
  @status = status
  @jira_response_body
end

JIRA_CONFIG[:issuecount_mapping].each do |mappingName, filter|
  SCHEDULER.every '10m', :first_in => 0 do
    total_count = case filter
    when 'Staging Rejected','Needs Changes'
      next
    when 'Rejected'
      ['Rejected','Staging Rejected','Needs Changes'].map do |status|
        number_of_issues(status)
      end.reduce(:+)
    else
      number_of_issues(filter)
    end

    total_points = case filter
    when 'Staging Rejected','Needs Changes'
      next
    when 'Rejected'
      ['Rejected','Staging Rejected','Needs Changes'].map do |status|
        sum_of_points(status)
      end.compact.reduce(:+)
    else
      sum_of_points(filter)
    end

    send_event(mappingName, {current: total_count || 0, points: total_points || 0})
  end
end

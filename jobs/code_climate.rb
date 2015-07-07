require 'net/http'
require 'json'

SCHEDULER.every '1h', :first_in => 0 do |job|
  repo_id = ENV['CODE_CLIMATE_REPO_ID']
  api_token = ENV['CODE_CLIMATE_API_TOKEN']

  uri = URI.parse("https://codeclimate.com/api/repos/#{repo_id}/branches/master")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  request.set_form_data({api_token: api_token})
  response = http.request(request)
  stats = JSON.parse(response.body)
  current_gpa = stats['last_snapshot']['gpa'].to_f
  last_gpa = stats['previous_snapshot']['gpa'].to_f
  send_event("code-climate", {current: current_gpa, last: last_gpa})
end

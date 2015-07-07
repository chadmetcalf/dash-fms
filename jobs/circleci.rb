require 'circleci'

module Constants
  STATUSES = %w[failed passed running started broken timedout no_tests fixed success canceled]
  FAILED, PASSED, RUNNING, STARTED, BROKEN, TIMEDOUT, NOTESTS, FIXED, SUCCESS, CANCELED = STATUSES
  FAILED_C   = 0.05
  BROKEN_C   = 0.05
  TIMEDOUT_C = 0.3
  NO_TESTS_C = 0.5
  CANCELED_C = 0.5
  RUNNING_C  = 1.0
  STARTED_C  = 1.0
  FIXED_C    = 1.0
  PASSED_C   = 1.0
  SUCCESS_C  = 1.0
end

def broken_or_no_builds
  {
    label: 'N/A',
    value: 'N/A',
    committer: '',
    state: 'broken',
    climate: ''
  }
end

def get_climate(build = {})
  return '|' if build.empty?

  factor = Constants.const_get("#{build['status'].upcase}_C") rescue nil

  case factor
  when 0.0..0.25  then '9'
  when 0.26..0.5  then '7'
  when 0.51..0.75 then '1'
  when 0.76..1.0  then 'v'
  else
    '|'
  end
end

def build_info
  get_builds.map do |build|
    return broken_or_no_builds if build.nil? || build.empty?

    {
      label: "Build ##{build['build_num'].to_s}",
      value: build['subject'],
      committer: build['committer_name'],
      state: build['status'],
      climate: get_climate(build)
    }
  end
end

def get_builds
  CircleCi.configure { |c| c.token = ENV['CIRCLECI_API_TOKEN'] }

  res = CircleCi::Project.recent_builds(ENV['CIRCLECI_USER'], ENV['CIRCLECI_REPO'])
  return [] unless res.try(:code) == 200
  return [] unless res.body.is_a?(Array)

  res.body.select{ |b| b['branch'] ==  'master' }
rescue
  []
end

SCHEDULER.every('15m', { first_in: '2s', allow_overlapping: false }) do
  send_event('circleci', { items: build_info })
end

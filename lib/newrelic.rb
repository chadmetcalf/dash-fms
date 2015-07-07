require 'yaml'
require 'newrelic_api'

class Newrelic

  attr_reader :metric, :points

  def initialize(options = {})
    @metric  = options.fetch(:metric, 'Apdex')
    @points  = points
  end

  def points
    unless history === false
      history['data']['points'].map{|a| Hash[a.map{|k,v| [k.to_sym,v] }] }
    else
      (0..59).map{|a| { x: a, y: 0 } }
    end
  end

  def history
    YAML.load Sinatra::Application.settings.history[stored_name].to_s
  end

  def get_value
    value = app.threshold_values.find{|v| v.name.eql? @metric}.metric_value
  end

  def stored_name
    "newrelic_#{@metric.gsub(/ /,'_')}"
  end

  def newrelic_account
    NewRelicApi.api_key = api_key
    NewRelicApi::Account.find(:first)
  end

  def app
    # Find the first app that matches the name
    newrelic_account.applications.find { |i| i.id == app_id.to_i }
  end

  def app_id
    ENV['NEWRELIC_APP_ID']
  end

  def api_key
    ENV['NEWRELIC_API_KEY']
  end
end

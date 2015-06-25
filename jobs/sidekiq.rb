require 'sidekiq/api'

Sidekiq.configure_client do |config|
  config.redis = { url:  ENV['SIDEKIQ_REDIS_URI'], namespace:  ENV['SIDEKIQ_REDIS_NAMESPACE'] }
end

SCHEDULER.every '30s' do
  stats = Sidekiq::Stats.new

  metrics = [
              {label: 'Workers', value: stats.workers_size},
              {label: 'Enqueued', value: stats.enqueued},
              {label: 'Processed', value: stats.processed},
              {label: 'Failed', value: stats.failed},
              {label: 'Retries', value: stats.retry_size},
              {label: 'Dead', value: stats.dead_size}
            ]
  send_event('sidekiq', {metrics: metrics})
end

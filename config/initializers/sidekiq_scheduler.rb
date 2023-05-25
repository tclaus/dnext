# frozen_string_literal: true

# Some recurring background jobs can take a lot of resources, and others even
# include pinging other pods, like recurring_pod_check. Having all jobs run at
# 0 UTC causes a high local load, as well as a little bit of DDoSing through
# the network, as pods try to ping each other.
#
# As Sidekiq-Cron does not support random offsets, we have to take care of that
# ourselves, so let's add jobs with random work times.

module SidekiqScheduler
  # rubocop:disable Metrics/MethodLength
  def self.default_job_config
    random_hour = lambda { rand(24) }
    random_minute = lambda { rand(60) }

    {
      check_birthday:              {
        cron:  "0 0 * * *",
        class: "Workers::CheckBirthday"
      },

      clean_cached_files:          {
        cron:  "#{random_minute.call} #{random_hour.call} * * *",
        class: "Workers::CleanCachedFiles"
      },

      cleanup_old_exports:         {
        cron:  "#{random_minute.call} #{random_hour.call} * * *",
        class: "Workers::CleanupOldExports"
      },

      cleanup_pending_photos:      {
        cron:  "#{random_minute.call} #{random_hour.call} * * *",
        class: "Workers::CleanupPendingPhotos"
      },

      queue_users_for_removal:     {
        cron:  "#{random_minute.call} #{random_hour.call} * * *",
        class: "Workers::QueueUsersForRemoval"
      },

      recheck_scheduled_pods:      {
        cron:  "*/30 * * * *",
        class: "Workers::RecheckScheduledPods"
      },

      recurring_pod_check:         {
        cron:  "#{random_minute.call} #{random_hour.call} * * *",
        class: "Workers::RecurringPodCheck"
      },

      cleanup_never_used_accounts: {
        cron:  "#{random_minute.call} 12 * * *",
        class: "Workers::RemoveUnusedAccounts"
      },

      load_public_posts_from_pods: {
        cron:  "#{random_minute.call} #{random_hour.call} * * *",
        class: "Workers::FetchPublicPostsFromPodsJob"
      }
    }
  end

  # rubocop:enable Metrics/MethodLength

  def self.valid_config?(path)
    return false unless File.exist?(path)

    current_config = YAML.load_file(path)

    # If they key don't match the current default config keys, a new job has
    # been added, so we need to regenerate the config to have the new job
    # running
    return false unless current_config.keys == default_job_config.keys

    # If recurring_pod_check is still running at midnight UTC, the config file
    # is probably from a previous version, and that's bad, so we need to
    # regenerate
    current_config[:recurring_pod_check][:cron] != "0 0 * * *"
  end

  def self.regenerate_config(path)
    job_config = default_job_config
    File.write(path, job_config.to_yaml)
  end
end
if Sidekiq.server?
  schedule_file_path = Rails.root.join("config/schedule.yml")
  SidekiqScheduler.regenerate_config(schedule_file_path) unless SidekiqScheduler.valid_config?(schedule_file_path)

  Rails.application.reloader.to_prepare do
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file_path)
  end
end

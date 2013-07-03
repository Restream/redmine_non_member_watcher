require 'watchers_controller'

module RedmineNonMemberWatcher::Patches
  module WatchersControllerPatch
    extend ActiveSupport::Concern

    included do
      skip_before_filter :check_project_privacy
      before_filter :check_project_privacy, :only => [:watch]
      before_filter :check_project_privacy_or_watched, :only => [:unwatch]
    end

    # allow self-unwatch
    def check_project_privacy_or_watched
      if User.current.allowed_to?(:view_watched_issues, @project) &&
          @watched.watched_by?(User.current)
        true
      else
        check_project_privacy
      end
    end
  end
end

unless WatchersController.included_modules.include? RedmineNonMemberWatcher::Patches::WatchersControllerPatch
  WatchersController.send :include, RedmineNonMemberWatcher::Patches::WatchersControllerPatch
end

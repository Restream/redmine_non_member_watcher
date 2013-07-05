require 'watchers_controller'

module RedmineNonMemberWatcher::Patches
  module WatchersControllerPatch
    extend ActiveSupport::Concern

    private

    # allow to self-unwatch
    def check_project_privacy
      allowed_to_unwatch? ? true : super
    end

    def allowed_to_unwatch?
      action_name == 'unwatch' &&
          User.current.allowed_to?(:view_watched_issues, @project) &&
          @watched.watched_by?(User.current)
    end
  end
end

unless WatchersController.included_modules.include? RedmineNonMemberWatcher::Patches::WatchersControllerPatch
  WatchersController.send :include, RedmineNonMemberWatcher::Patches::WatchersControllerPatch
end

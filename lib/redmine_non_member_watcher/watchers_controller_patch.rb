module RedmineNonMemberWatcher
  module WatchersControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :skip_before_filter, :check_project_privacy
      base.send :before_filter, :check_project_privacy, :only => [:watch]
      base.send :before_filter, :check_project_privacy_or_watched, :only => [:unwatch]
    end

    module InstanceMethods

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
end

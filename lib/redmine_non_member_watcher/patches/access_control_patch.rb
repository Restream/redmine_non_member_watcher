require 'redmine/access_control'

module RedmineNonMemberWatcher::Patches
  module AccessControlPatch
    extend ActiveSupport::Concern

    module ClassMethods
      def non_member_watcher_permissions
        @permissions ||= @permissions.select {|p| p.require_member_non_watcher?}
      end
    end
  end
end

module RedmineNonMemberWatcher::Patches
  module AccessControlPermissionPatch
    extend ActiveSupport::Concern

    def require_member_non_watcher?
      @require && @require == :member_non_watcher
    end
  end
end

unless Redmine::AccessControl.included_modules.include? RedmineNonMemberWatcher::Patches::AccessControlPatch
  Redmine::AccessControl.send :include, RedmineNonMemberWatcher::Patches::AccessControlPatch
end

unless Redmine::AccessControl::Permission.included_modules.include? RedmineNonMemberWatcher::Patches::AccessControlPermissionPatch
  Redmine::AccessControl::Permission.send :include, RedmineNonMemberWatcher::Patches::AccessControlPermissionPatch
end

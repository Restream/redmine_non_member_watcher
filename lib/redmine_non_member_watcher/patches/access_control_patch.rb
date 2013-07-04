require 'redmine/access_control'

module RedmineNonMemberWatcher::Patches
  module AccessControlPatch
    extend ActiveSupport::Concern

    module ClassMethods
      def non_member_watcher_permissions
        permissions.select do |p|
          [:edit_issues, :add_issue_notes].include?(p.name) ||
              p.require_non_member_watcher?
        end
      end

      def non_member_author_permissions
        permissions.select do |p|
          [:edit_issues, :add_issue_notes].include?(p.name) ||
              p.require_non_member_author?
        end
      end
    end
  end
end

module RedmineNonMemberWatcher::Patches
  module AccessControlPermissionPatch
    extend ActiveSupport::Concern

    def require_non_member_watcher?
      @require && @require == :non_member_watcher
    end

    def require_non_member_author?
      @require && @require == :non_member_author
    end
  end
end

unless Redmine::AccessControl.included_modules.include? RedmineNonMemberWatcher::Patches::AccessControlPatch
  Redmine::AccessControl.send :include, RedmineNonMemberWatcher::Patches::AccessControlPatch
end

unless Redmine::AccessControl::Permission.included_modules.include? RedmineNonMemberWatcher::Patches::AccessControlPermissionPatch
  Redmine::AccessControl::Permission.send :include, RedmineNonMemberWatcher::Patches::AccessControlPermissionPatch
end

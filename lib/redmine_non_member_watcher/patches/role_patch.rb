require_dependency 'role'

module RedmineNonMemberWatcher::Patches
  module RolePatch
    extend ActiveSupport::Concern

    included do
      BUILTIN_NON_MEMBER_WATCHER = 301
      BUILTIN_NON_MEMBER_AUTHOR  = 302

      alias_method_chain :setable_permissions, :non_member_roles
      alias_method_chain :allowed_permissions, :non_member_watcher
    end

    module ClassMethods
      def non_member_watcher
        find_or_create_system_role Role::BUILTIN_NON_MEMBER_WATCHER, 'Non member watcher'
      end

      def non_member_author
        find_or_create_system_role Role::BUILTIN_NON_MEMBER_AUTHOR, 'Non member author'
      end
    end

    def non_member_watcher?
      self.builtin == Role::BUILTIN_NON_MEMBER_WATCHER
    end

    def non_member_author?
      self.builtin == Role::BUILTIN_NON_MEMBER_AUTHOR
    end

    private

    def setable_permissions_with_non_member_roles
      case
        when non_member_watcher?
          Redmine::AccessControl.non_member_watcher_permissions

        when non_member_author?
          Redmine::AccessControl.non_member_author_permissions

        else
          setable_permissions_without_non_member_roles.reject do |perm|
            perm.require_non_member_watcher? || perm.require_non_member_author?
          end
      end
    end

    def allowed_permissions_with_non_member_watcher
      if non_member_watcher? || non_member_author?
        permissions
      else
        allowed_permissions_without_non_member_watcher
      end
    end
  end
end

require 'user'

module RedmineNonMemberWatcher::Patches
  module UserPatch
    extend ActiveSupport::Concern

    included do
      alias_method_chain :roles_for_project, :watcher
      alias_method_chain :allowed_to?, :non_member_watcher
    end

    def roles_for_project_with_watcher(project)
      roles = roles_for_project_without_watcher(project)
      roles << Role.non_member_watcher if roles.include? Role.non_member
      roles
    end

    def allowed_to_with_non_member_watcher?(action, context, options={}, &block)
      allowed_to_without_non_member_watcher?(action, context, options, &block) ||
        if context && context.is_a?(Project)
          roles = roles_for_project(context)
          roles.detect { |role|
            role == Role.non_member_watcher &&
                role.allowed_to?(action) &&
                (block_given? ? yield(role, self) : true)
          } || false
        else
          false
        end
    end
  end
end

unless User.included_modules.include? RedmineNonMemberWatcher::Patches::UserPatch
  User.send :include, RedmineNonMemberWatcher::Patches::UserPatch
end

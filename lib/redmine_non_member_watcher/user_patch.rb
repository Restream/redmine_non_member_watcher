module RedmineNonMemberWatcher
  module UserPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :alias_method_chain, :roles_for_project, :watcher
      base.send :alias_method_chain, :allowed_to?, :non_member_watcher
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
      end
    end

    module InstanceMethods
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
end

module RedmineNonMemberWatcher
  module AccessControlPatch
    def self.included(base)
      base.extend ClassMethods
      base::Permission.send :include, Permission::InstanceMethods
    end

    module ClassMethods
      def non_member_watcher_permissions
        @permissions ||= @permissions.select {|p| p.require_member_non_watcher?}
      end
    end

    module Permission
      module InstanceMethods
        def require_member_non_watcher?
          @require && @require == :member_non_watcher
        end
      end
    end
  end
end

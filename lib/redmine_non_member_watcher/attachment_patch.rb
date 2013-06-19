module RedmineNonMemberWatcher
  module AttachmentPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :alias_method_chain, :visible?, :non_member_watcher
    end

    module InstanceMethods
      # Issue maybe visible when project is not
      def visible_with_non_member_watcher?(user = User.current)
        visible_without_non_member_watcher?(user) || (
            container &&
            container.is_a?(Issue) &&
            container.visible?(user))
      end
    end
  end
end

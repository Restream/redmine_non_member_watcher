module RedmineNonMemberWatcher
  module IssuePatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :alias_method_chain, :visible?, :watchers
    end

    module InstanceMethods
      def visible_with_watchers?(usr = nil)
        visible_without_watchers?(usr) ||
          (usr || User.current).allowed_to?(:view_issues, self.project) do |role, user|
            case role.issues_visibility
              when 'watch'
                self.watchers.detect{ |w| w.user == user }.present?
              else
                false
            end
          end
      end
    end
  end
end

module RedmineNonMemberWatcher
  module IssuePatch
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :visible_condition, :watchers
        end
      end

      base.send :include, InstanceMethods
      base.send :alias_method_chain, :visible?, :watchers
    end

    module ClassMethods
      def visible_condition_with_watchers(user, options={})
        issues = visible_condition_without_watchers(user, options)

        watched_issues_cond = watched_issues_condition(user, options)
        if watched_issues_cond
          "(#{issues}) OR (#{watched_issues_cond})"
        else
          issues
        end
      end

      def watched_issues_condition(user, options={})
        Project.allowed_to_condition(user, :view_watched_issues_list, options) do |role, user|
          case role.issues_visibility
            when 'watch'
              ["EXISTS (SELECT * FROM #{Watcher.table_name} as wts",
                "WHERE wts.watchable_type = 'Issue'",
                "AND wts.watchable_id = #{Issue.table_name}.id",
                "AND wts.user_id = #{user.id})"].join(" ")
            else
              nil
          end
        end
      end
    end

    module InstanceMethods
      def visible_with_watchers?(usr = nil)
        visible_without_watchers?(usr) ||
          (usr || User.current).allowed_to?(:view_watched_issues, self.project) do |role, user|
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

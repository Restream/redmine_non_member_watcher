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

        if (watched_issues = watched_issues_condition(user, options))
          "(#{issues}) OR (#{watched_issues})"
        else
          issues
        end
      end

      def watched_issues_condition(user, options={})
        Project.allowed_to_condition(user, :view_watched_issues_list, options) do |role, user|
          case role.issues_visibility
            when 'watch'
              "#{Issue.table_name}.id in (select wrs.watchable_id from #{Watcher.table_name} wrs where wrs.watchable_type = 'Issue' and wrs.user_id = #{user.id})"
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

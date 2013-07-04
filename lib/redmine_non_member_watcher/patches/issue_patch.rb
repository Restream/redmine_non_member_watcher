require 'issue'

module RedmineNonMemberWatcher::Patches
  module IssuePatch
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :visible_condition, :non_member_roles
      end
      alias_method_chain :visible?, :watchers
      alias_method_chain :visible?, :authors
    end

    module ClassMethods
      def visible_condition_with_non_member_roles(user, options={})
        issues_cond = visible_condition_without_non_member_roles(user, options)
        watched_issues_cond = watched_issues_condition(user, options)
        own_issues_cond = own_issues_condition(user, options)
        [
            issues_cond,
            watched_issues_cond,
            own_issues_cond
        ].map { |c| "(#{c})" }.join(' OR ')
      end

      def watched_issues_condition(user, options={})
        Project.allowed_to_condition(user, :view_watched_issues_list, options) do |role, user|
          ["EXISTS (SELECT * FROM #{Watcher.table_name} as wts",
            "WHERE wts.watchable_type = 'Issue'",
            "AND wts.watchable_id = #{Issue.table_name}.id",
            "AND wts.user_id = #{user.id})"].join(" ")
        end
      end

      def own_issues_condition(user, options={})
        Project.allowed_to_condition(user, :view_own_issues_list, options) do |role, user|
          "#{Issue.table_name}.author_id = #{user.id}"
        end
      end
    end

    def visible_with_watchers?(usr = nil)
      visible_without_watchers?(usr) ||
        (usr || User.current).allowed_to?(:view_watched_issues, self.project) do |role, user|
          self.watchers.detect{ |w| w.user == user }.present?
        end
    end

    def visible_with_authors?(usr = nil)
      visible_without_authors?(usr) ||
        (usr || User.current).allowed_to?(:view_own_issues, self.project) do |role, user|
          self.author_id == user.id
        end
    end
  end
end

unless Issue.included_modules.include? RedmineNonMemberWatcher::Patches::IssuePatch
  Issue.send :include, RedmineNonMemberWatcher::Patches::IssuePatch
end

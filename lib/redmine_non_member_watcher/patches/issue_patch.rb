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
        conditions = []
        conditions << visible_condition_with_watched_issues(user, options)

        if user.logged?
          watched_issues_cond = watched_issues_condition(user, options)
          conditions << watched_issues_cond unless watched_issues_cond == '1=0'

          own_issues_cond = own_issues_condition(user, options)
          conditions << own_issues_cond unless own_issues_cond == '1=0'
        end

        conditions.map { |c| "(#{c})" }.join(' OR ')
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

      # See issues with watched items
      def visible_condition_with_watched_issues(user, options={})
        Project.allowed_to_condition(user, :view_issues, options) do |role, user|
          if user.logged?

            # Add watched issues to list if allowed
            watched_condition = if role.allowed_to?( :view_watched_issues_list )
              <<-SQL
                OR EXISTS ( SELECT * FROM #{ Watcher.table_name } as wts
                            WHERE wts.watchable_type = 'Issue'
                            AND wts.watchable_id = #{Issue.table_name}.id
                            AND wts.user_id = #{ user.id } )
              SQL
            else
              ''
            end

            case role.issues_visibility
              when 'all'
                nil
              when 'default'
                user_ids = [user.id] + user.groups.map(&:id)
                "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) #{ watched_condition })"
              when 'own'
                user_ids = [user.id] + user.groups.map(&:id)
                "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) #{ watched_condition })"
              else
                '1=0'
            end
          else
            "(#{table_name}.is_private = #{connection.quoted_false})"
          end
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

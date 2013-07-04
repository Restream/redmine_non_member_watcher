require 'project'

module RedmineNonMemberWatcher::Patches
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :allowed_to_condition, :watchers
      end
    end

    module ClassMethods
      def allowed_to_condition_with_watchers(user, permission, options={}, &block)
        if !options[:member] && user.logged? && permission == :view_watched_issues_list
          allowed_to_condition_for_watchers(user, permission, options, &block)

        elsif !options[:member] && user.logged? && permission == :view_own_issues_list
          allowed_to_condition_for_authors(user, permission, options, &block)

        else
          allowed_to_condition_without_watchers(user, permission, options, &block)
        end
      end

      private

      def allowed_to_condition_for_watchers(user, permission, options={}, &block)
        if Role.non_member_watcher.allowed_to?(permission)
          base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
          if perm = Redmine::AccessControl.permission(permission)
            unless perm.project_module.nil?
              # If the permission belongs to a project module, make sure the module is enabled
              base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
            end
          end

          if options[:project]
            project_statement = "#{Project.table_name}.id = #{options[:project].id}"
            project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
            base_statement = "(#{project_statement}) AND (#{base_statement})"
          else
            projects_statement = Issue.watched_by(user.id).map(&:project_id).uniq.join(",")
            unless projects_statement.blank?
              base_statement = "(#{Project.table_name}.id in (#{projects_statement})) AND (#{base_statement})"
            end
          end

          if block_given?
            block_statement = yield(Role.non_member_watcher, user)
            base_statement = "(#{base_statement}) AND (#{block_statement})" unless block_statement.blank?
          end

          base_statement
        else
          "1=0"
        end
      end

      def allowed_to_condition_for_authors(user, permission, options={}, &block)
        if Role.non_member_author.allowed_to?(permission)
          base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
          if perm = Redmine::AccessControl.permission(permission)
            unless perm.project_module.nil?
              # If the permission belongs to a project module, make sure the module is enabled
              base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
            end
          end

          if options[:project]
            project_statement = "#{Project.table_name}.id = #{options[:project].id}"
            project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
            base_statement = "(#{project_statement}) AND (#{base_statement})"
          else
            projects_statement =
                Issue.where(:author_id => user.id).uniq.pluck(:project_id).join(",")
            unless projects_statement.blank?
              base_statement = "(#{Project.table_name}.id in (#{projects_statement})) AND (#{base_statement})"
            end
          end

          if block_given?
            block_statement = yield(Role.non_member_author, user)
            base_statement = "(#{base_statement}) AND (#{block_statement})" unless block_statement.blank?
          end

          base_statement
        else
          "1=0"
        end
      end

    end
  end
end

unless Project.included_modules.include? RedmineNonMemberWatcher::Patches::ProjectPatch
  Project.send :include, RedmineNonMemberWatcher::Patches::ProjectPatch
end

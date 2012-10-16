module RedmineNonMemberWatcher
  module ProjectPatch
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        class << self
          alias_method_chain :allowed_to_condition, :watchers
        end
      end
    end

    module ClassMethods
      def allowed_to_condition_with_watchers(user, permission, options={}, &block)
        watcher_permissions = [:view_watched_issues_list]
        if !options[:member] && user.logged? && watcher_permissions.include?(permission)

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
            end
            statement_by_role = {
                Role.non_member_watcher => <<-SQLEND
                    #{Project.table_name}.id in (
                        SELECT w_issues.project_id
                        FROM #{Issue.table_name} w_issues
                          INNER JOIN #{Watcher.table_name} w_watchers ON
                            w_watchers.watchable_type = 'Issue' AND
                            w_watchers.watchable_id = w_issues.id AND
                            w_watchers.user_id = #{user.id} )
                SQLEND
            }
            if block_given?
              statement_by_role.each do |role, statement|
                if (s = yield(role, user))
                  statement_by_role[role] = "(#{statement} AND (#{s}))"
                end
              end
            end
            "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
          else
            "1=0"
          end

        else
          allowed_to_condition_without_watchers(user, permission, options, &block)
        end
      end
    end
  end
end

require 'role'

module RedmineNonMemberWatcher::Patches
  module RolePatch
    extend ActiveSupport::Concern

    included do |base|
      self.send :redefine_issues_visibility, base

      # define new builtin constant
      BUILTIN_NON_MEMBER_WATCHER = 301

      alias_method_chain :setable_permissions, :non_member_watcher
      alias_method_chain :allowed_permissions, :non_member_watcher
    end

    module ClassMethods
      # Return the builtin 'non member watcher' role.  If the role doesn't exist,
      # it will be created on the fly.
      def non_member_watcher
        builtin = Role::BUILTIN_NON_MEMBER_WATCHER
        role = where(:builtin => builtin)
        if role.nil?
          name = 'Non member watcher'
          role = create(
              :names => name,
              :position => 0,
              :builtin => builtin,
              :issues_visibility => 'watch',
              :permissions => [
                  :view_watched_issues,
                  :view_watched_issues_list,
                  :receive_email_notifications,
                  :edit_issues,
                  :add_issue_notes]
          )
          if role.new_record?
            logger.error "Unable to create the #{name} role.\n" +
                             role.errors.full_messages.join("\n")
            raise "Unable to create the #{name} role."
          end
        end
        role
      end

      private

      def redefine_issues_visibility(base)
        new_issues_visibility_options = base::ISSUES_VISIBILITY_OPTIONS + [
            ['watch', :label_issues_visibility_watch]
        ]

        old_validation_opts = base::ISSUES_VISIBILITY_OPTIONS.collect(&:first)

        # redefine ISSUES_VISIBILITY_OPTIONS constant
        base.send :remove_const, :ISSUES_VISIBILITY_OPTIONS
        base.const_set :ISSUES_VISIBILITY_OPTIONS, new_issues_visibility_options

        # find validation callback with the old list and disable it
        filters = Role._validate_callbacks.select do |c|
          c.options[:in] == old_validation_opts
        end.map(&:filter)

        filters.each do |filter|
          Role.skip_callback(:validate, :before, filter)
        end

        # define callback with new list
        base.send :validates_inclusion_of, :issues_visibility,
                  :in => base::ISSUES_VISIBILITY_OPTIONS.collect(&:first),
                  :if => lambda {|role| role.respond_to?(:issues_visibility)}
      end
    end

    def setable_permissions_with_non_member_watcher
      perms = [:edit_issues, :add_issue_notes]
      if self.builtin == Role::BUILTIN_NON_MEMBER_WATCHER
        Redmine::AccessControl.permissions.select do |perm|
          perms.include?(perm.name) || perm.require_member_non_watcher?
        end
      else
        setable_permissions_without_non_member_watcher.select do |perm|
          !perm.require_member_non_watcher?
        end
      end
    end

    private

    def allowed_permissions_with_non_member_watcher
      if self.builtin == Role::BUILTIN_NON_MEMBER_WATCHER
        permissions
      else
        allowed_permissions_without_non_member_watcher
      end
    end
  end
end

unless Role.included_modules.include? RedmineNonMemberWatcher::Patches::RolePatch
  Role.send :include, RedmineNonMemberWatcher::Patches::RolePatch
end

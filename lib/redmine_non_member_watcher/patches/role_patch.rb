require 'role'

module RedmineNonMemberWatcher::Patches
  module RolePatch
    extend ActiveSupport::Concern

    included do |base|
      self.send :redefine_issues_visibility, base

      # define new builtin constants
      BUILTIN_NON_MEMBER_WATCHER = 301
      BUILTIN_NON_MEMBER_AUTHOR  = 302

      alias_method_chain :setable_permissions, :non_member_roles
    end

    module ClassMethods
      # Return the builtin 'non member watcher' role.
      # If the role doesn't exist,
      # it will be created on the fly with default options.
      def non_member_watcher
        find_or_create_system_role_with_options(
            Role::BUILTIN_NON_MEMBER_WATCHER,
            'Non member watcher',
            :issues_visibility => 'watch',
            :permissions => [
                :view_watched_issues,
                :view_watched_issues_list,
                :receive_watched_issues_notifications,
                :edit_issues,
                :add_issue_notes]
        )
      end

      # Return the builtin 'non member author' role.
      # If the role doesn't exist,
      # it will be created on the fly with default options.
      def non_member_author
        find_or_create_system_role_with_options(
            Role::BUILTIN_NON_MEMBER_AUTHOR,
            'Non member author',
            :issues_visibility => 'own',
            :permissions => [
                :view_own_issues,
                :view_own_issues_list,
                :receive_own_issues_notifications,
                :edit_issues,
                :add_issue_notes]
        )
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

      def find_or_create_system_role_with_options(*args)
        options = args.extract_options!
        builtin, name = args[0], args[1]
        role = where(:builtin => builtin).first
        if role.nil?
          options.merge!(:name => name, :position => 0)
          role = create(options) do |r|
            r.builtin = builtin
          end
          raise "Unable to create the #{name} role." if role.new_record?
        end
        role
      end
    end

    def non_member_watcher?
      self.builtin == Role::BUILTIN_NON_MEMBER_WATCHER
    end

    def non_member_author?
      self.builtin == Role::BUILTIN_NON_MEMBER_AUTHOR
    end

    def setable_permissions_with_non_member_roles
      case
        when non_member_watcher?
          Redmine::AccessControl.non_member_watcher_permissions

        when non_member_author?
          Redmine::AccessControl.non_member_author_permissions

        else
          setable_permissions_without_non_member_roles.reject do |perm|
            perm.require_non_member_watcher? || perm.require_non_member_author?
          end
      end
    end
  end
end

unless Role.included_modules.include? RedmineNonMemberWatcher::Patches::RolePatch
  Role.send :include, RedmineNonMemberWatcher::Patches::RolePatch
end

module RedmineNonMemberWatcher
  module RolePatch
    def self.included(base)
      redefine_issues_visibility(base)

      # define new builtin constant
      base.const_set :BUILTIN_NON_MEMBER_WATCHER, 301

      base.extend ClassMethods
    end

    module ClassMethods
      # Return the builtin 'non member watcher' role.  If the role doesn't exist,
      # it will be created on the fly.
      def non_member_watcher
        find_or_create_system_role(Role::BUILTIN_NON_MEMBER_WATCHER, 'Non member watcher')
      end
    end

    private

    def self.redefine_issues_visibility(base)
      new_issues_visibility_options = base::ISSUES_VISIBILITY_OPTIONS + [
          ['watch', :label_issues_visibility_watch]
      ]

      old_validation_opts = base::ISSUES_VISIBILITY_OPTIONS.collect(&:first)

      # redefine ISSUES_VISIBILITY_OPTIONS constant
      base.send :remove_const, :ISSUES_VISIBILITY_OPTIONS
      base.const_set :ISSUES_VISIBILITY_OPTIONS, new_issues_visibility_options

      # find validation callback with the old list and disable it
      # todo: can't find the best way to redefine callback
      Role.validate_callback_chain.each do |callback|
        if callback.options[:in] == old_validation_opts
          callback.instance_eval { @method = proc { |*args| true } }
        end
      end

      # define callback with new list
      base.send :validates_inclusion_of, :issues_visibility,
                :in => base::ISSUES_VISIBILITY_OPTIONS.collect(&:first),
                :if => lambda {|role| role.respond_to?(:issues_visibility)}
    end
  end
end

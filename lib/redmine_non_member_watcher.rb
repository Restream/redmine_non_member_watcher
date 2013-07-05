require 'active_support/concern'

module RedmineNonMemberWatcher
end

ActionDispatch::Callbacks.to_prepare do
  require 'redmine_non_member_watcher/patches/project_patch'
  require 'redmine_non_member_watcher/patches/user_patch'
  require 'redmine_non_member_watcher/patches/role_patch'
  require 'redmine_non_member_watcher/patches/issue_patch'
  require 'redmine_non_member_watcher/patches/attachment_patch'
  require 'redmine_non_member_watcher/patches/watchers_controller_patch'
  require 'redmine_non_member_watcher/patches/access_control_patch'

  # if redmine default data loaded then try load default data for this plugin
  Role.non_member_watcher if Role.any? rescue nil
  Role.non_member_author if Role.any? rescue nil
end

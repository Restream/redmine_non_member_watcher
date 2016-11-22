require 'active_support/concern'

module RedmineNonMemberWatcher
end

require_dependency 'redmine_non_member_watcher/patches/project_patch'
require_dependency 'redmine_non_member_watcher/patches/user_patch'
require_dependency 'redmine_non_member_watcher/patches/role_patch'
require_dependency 'redmine_non_member_watcher/patches/issue_patch'
require_dependency 'redmine_non_member_watcher/patches/attachment_patch'
require_dependency 'redmine_non_member_watcher/patches/watchers_controller_patch'
require_dependency 'redmine_non_member_watcher/patches/access_control_patch'

ActionDispatch::Callbacks.to_prepare do

  unless Project.included_modules.include? RedmineNonMemberWatcher::Patches::ProjectPatch
    Project.send :include, RedmineNonMemberWatcher::Patches::ProjectPatch
  end

  unless User.included_modules.include? RedmineNonMemberWatcher::Patches::UserPatch
    User.send :include, RedmineNonMemberWatcher::Patches::UserPatch
  end

  unless Role.included_modules.include? RedmineNonMemberWatcher::Patches::RolePatch
    Role.send :include, RedmineNonMemberWatcher::Patches::RolePatch
  end

  unless Issue.included_modules.include? RedmineNonMemberWatcher::Patches::IssuePatch
    Issue.send :include, RedmineNonMemberWatcher::Patches::IssuePatch
  end

  unless Attachment.included_modules.include? RedmineNonMemberWatcher::Patches::AttachmentPatch
    Attachment.send :include, RedmineNonMemberWatcher::Patches::AttachmentPatch
  end

  unless WatchersController.included_modules.include? RedmineNonMemberWatcher::Patches::WatchersControllerPatch
    WatchersController.send :include, RedmineNonMemberWatcher::Patches::WatchersControllerPatch
  end

  unless Redmine::AccessControl.included_modules.include? RedmineNonMemberWatcher::Patches::AccessControlPatch
    Redmine::AccessControl.send :include, RedmineNonMemberWatcher::Patches::AccessControlPatch
  end

  unless Redmine::AccessControl::Permission.included_modules.include? RedmineNonMemberWatcher::Patches::AccessControlPermissionPatch
    Redmine::AccessControl::Permission.send :include, RedmineNonMemberWatcher::Patches::AccessControlPermissionPatch
  end

  # if redmine default data loaded then try load default data for this plugin
  Role.non_member_watcher if Role.any? rescue nil
  Role.non_member_author if Role.any? rescue nil
end

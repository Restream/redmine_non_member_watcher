require 'redmine'

callbacks = if Redmine::VERSION::MAJOR < 2
  require 'dispatcher'
  Dispatcher
else
  ActionDispatch::Callbacks
end

callbacks.to_prepare do
  require_dependency 'project'
  unless Project.included_modules.include? RedmineNonMemberWatcher::ProjectPatch
    Project.send :include, RedmineNonMemberWatcher::ProjectPatch
  end
  require_dependency 'user'
  unless User.included_modules.include? RedmineNonMemberWatcher::UserPatch
    User.send :include, RedmineNonMemberWatcher::UserPatch
  end
  require_dependency 'role'
  unless Role.included_modules.include? RedmineNonMemberWatcher::RolePatch
    Role.send :include, RedmineNonMemberWatcher::RolePatch
  end
  require_dependency 'issue'
  unless Issue.included_modules.include? RedmineNonMemberWatcher::IssuePatch
    Issue.send :include, RedmineNonMemberWatcher::IssuePatch
  end
  require_dependency 'attachment'
  unless Attachment.included_modules.include? RedmineNonMemberWatcher::AttachmentPatch
    Attachment.send :include, RedmineNonMemberWatcher::AttachmentPatch
  end
  require_dependency 'watchers_controller'
  unless WatchersController.included_modules.include? RedmineNonMemberWatcher::WatchersControllerPatch
    WatchersController.send :include, RedmineNonMemberWatcher::WatchersControllerPatch
  end
  require_dependency 'redmine/access_control'
  unless Redmine::AccessControl.included_modules.include? RedmineNonMemberWatcher::AccessControlPatch
    Redmine::AccessControl.send :include, RedmineNonMemberWatcher::AccessControlPatch
  end
  # if redmine default data loaded then try load default data for this plugin
  begin
    unless Redmine::DefaultData::Loader.no_data?
      if RedmineNonMemberWatcher::DefaultData::Loader.no_data?
        RedmineNonMemberWatcher::DefaultData::Loader.load
      end
    end
  rescue
    # possible there is no tables yet
  end
end

Redmine::Plugin.register :redmine_non_member_watcher do
  name 'Redmine Non Member Watcher plugin'
  author 'danil.tashkinov@gmail.com'
  description 'Redmine plugin that adds new system role "Non member watcher"'
  version '0.0.8'
  url 'https://github.com/Undev/redmine_non_member_watcher'
  author_url 'https://github.com/Undev'
  requires_redmine :version_or_higher => '1.4.0'

  project_module :issue_tracking do |map|
    map.permission :receive_email_notifications, {}, :require => :member_non_watcher
    map.permission :view_watched_issues, { :issues => [:show] }, :require => :member_non_watcher
    map.permission :view_watched_issues_list, { :issues => [:index] }, :require => :member_non_watcher
  end
end

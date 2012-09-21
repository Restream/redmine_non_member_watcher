require File.expand_path('../../../../test_helper', __FILE__)

class UserPatchTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues

  def setup
    @issue = Issue.find(1)
    @project = @issue.project

    # make project private
    @project.is_public = false
    @project.save!

    # non_member for issue project
    @watcher = User.find(4)

    @issue.add_watcher(@watcher)

    @role = Role.non_member_watcher
    @role.issues_visibility = 'watch'
    @role.save!
  end

  def test_watcher_has_non_member_watcher_role
    roles = @watcher.roles_for_project(@project)
    assert_include Role.non_member_watcher, roles
  end

  def test_watcher_has_permission_to_view_issues
    @role.permissions = [:view_watched_issues]
    @role.save!
    assert @watcher.allowed_to?(:view_watched_issues, @project)
  end

  def test_watcher_has_no_permission_to_view_issues
    @role.permissions = []
    @role.save!
    assert_false !!@watcher.allowed_to?(:view_watched_issues, @project)
  end

  def test_watcher_has_permission_to_receive_emails
    @role.permissions = [:view_watched_issues, :receive_email_notifications]
    @role.save!
    assert @watcher.allowed_to?(:receive_email_notifications, @project)
    assert_include @watcher.mail, @issue.watcher_recipients
  end

  def test_watcher_has_no_permission_to_receive_emails
    @role.permissions = []
    @role.save!
    assert_false !!@watcher.allowed_to?(:receive_email_notifications, @project)
    assert_not_include @watcher.mail, @issue.watcher_recipients
  end
end


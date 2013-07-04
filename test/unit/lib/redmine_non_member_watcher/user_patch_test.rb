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
    prepare_for_testing_non_meber_roles
  end

  def test_watcher_has_non_member_watcher_role
    roles = @watcher.roles_for_project(@project)
    assert_include Role.non_member_watcher, roles
  end

  def test_watcher_has_permission_to_view_issues
    role = Role.non_member_watcher
    role.permissions = [:view_watched_issues]
    role.save!
    assert @watcher.allowed_to?(:view_watched_issues, @project)
  end

  def test_watcher_has_no_permission_to_view_issues
    role = Role.non_member_watcher
    role.permissions = []
    role.save!
    assert_false !!@watcher.allowed_to?(:view_watched_issues, @project)
  end

  def test_watcher_has_permission_to_receive_emails
    role = Role.non_member_watcher
    role.permissions = [:view_watched_issues, :receive_watched_issues_notifications]
    role.save!
    assert @watcher.allowed_to?(:receive_watched_issues_notifications, @project)
    assert_include @watcher.mail, @issue.watcher_recipients
  end

  def test_watcher_has_no_permission_to_receive_emails
    role = Role.non_member_watcher
    role.permissions = []
    role.save!
    assert_false !!@watcher.allowed_to?(:receive_watched_issues_notifications, @project)
    assert_not_include @watcher.mail, @issue.watcher_recipients
  end

  def test_author_has_non_member_author_role
    roles = @author.roles_for_project(@project)
    assert_include Role.non_member_author, roles
  end

  def test_author_has_permission_to_view_issues
    role = Role.non_member_author
    role.permissions = [:view_own_issues]
    role.save!
    assert @author.allowed_to?(:view_own_issues, @project)
  end

  def test_author_has_no_permission_to_view_issues
    role = Role.non_member_author
    role.permissions = []
    role.save!
    assert_false !!@author.allowed_to?(:view_own_issues, @project)
  end

  def test_author_has_permission_to_receive_emails
    role = Role.non_member_author
    role.permissions = [:view_own_issues, :receive_own_issues_notifications]
    role.save!
    assert @author.allowed_to?(:receive_own_issues_notifications, @project)
    assert_include @author.mail, @issue.recipients
  end

  def test_author_has_no_permission_to_receive_emails
    role = Role.non_member_author
    role.permissions = []
    role.save!
    assert_false !!@author.allowed_to?(:receive_own_issues_notifications, @project)
    assert_not_include @author.mail, @issue.recipients
  end
end


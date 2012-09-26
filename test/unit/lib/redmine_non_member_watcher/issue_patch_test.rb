require File.expand_path('../../../../test_helper', __FILE__)

class IssuePatchTest < ActiveSupport::TestCase
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
    setup_non_member_watcher_role
  end

  def test_visible_for_non_member_watchers
    assert @issue.visible?(@watcher)
  end
end


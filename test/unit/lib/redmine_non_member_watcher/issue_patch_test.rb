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
    prepare_for_testing_non_meber_roles
  end

  def test_visible_for_non_member_watchers
    Role.non_member_watcher.update_attributes({
        :permissions => [:view_watched_issues]
    })
    assert @issue.visible?(@watcher)
  end

  def test_not_visible_for_non_member_watchers
    Role.non_member_watcher.update_attributes({
        :permissions => []
    })
    assert_equal false, @issue.visible?(@watcher)
  end

  def test_issue_included_in_visible_watcher_scope
    Role.non_member_watcher.update_attributes({
        :permissions => [:view_watched_issues, :view_watched_issues_list]
    })
    issues = Issue.visible(@watcher)
    assert_include @issue, issues
  end

  def test_issue_not_included_in_visible_watcher_scope
    Role.non_member_watcher.update_attributes({
        :permissions => []
    })
    issues = Issue.visible(@watcher)
    assert_not_include @issue, issues
  end

  def test_no_non_visible_issues_in_watcher_list
    Role.non_member_watcher.update_attributes({
        :permissions => [:view_watched_issues, :view_watched_issues_list]
    })
    issues = Issue.visible(@watcher)
    issues.each do |issue|
      assert issue.visible?(@watcher)
    end
  end

  def test_visible_for_non_member_authors
    Role.non_member_author.update_attributes({
        :permissions => [:view_own_issues]
    })
    assert @issue.visible?(@author)
  end

  def test_not_visible_for_non_member_authors
    Role.non_member_author.update_attributes({
        :permissions => []
    })
    assert_equal false, @issue.visible?(@author)
  end

  def test_issue_included_in_visible_scope
    Role.non_member_author.update_attributes({
        :permissions => [:view_own_issues, :view_own_issues_list]
    })
    issues = Issue.visible(@author)
    assert_include @issue, issues
  end

  def test_issue_not_included_in_visible_scope
    Role.non_member_author.update_attributes({
        :permissions => []
    })
    issues = Issue.visible(@author)
    assert_not_include @issue, issues
  end

  def test_no_non_visible_issues_in_list
    Role.non_member_author.update_attributes({
        :permissions => [:view_own_issues, :view_own_issues_list]
    })
    issues = Issue.visible(@author)
    issues.each do |issue|
      assert issue.visible?(@author)
    end
  end
end


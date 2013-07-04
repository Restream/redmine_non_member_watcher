require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class ActiveSupport::TestCase

  # @project -> { id: 1, public: false }
  # @issue -> { id: 1, attachments => [@attachment], watchers: [@watcher]
  # @author { id: 2, login: 'jsmith', authored_issues_in_project: [1, 2, 3, 5, 6, 7, 9, 10, 13, 14] }
  # @watcher { id: 4, login: 'rhill', watched_issues_in_project: [13, 5, 1] }
  def prepare_for_testing_non_meber_roles
    @issue = Issue.find(1)
    @attachment = Attachment.find(16)
    @issue.attachments << @attachment
    assert @issue.attachments.first
    set_fixtures_attachments_directory

    @project = @issue.project

    # make project private
    @project.is_public = false
    @project.save!

    # non_member watcher for issue project
    @watcher = User.find(4)
    @issue.add_watcher(@watcher)
    remove_user_from_project(@watcher)

    # non_member author for issue
    @author = User.find(2)
    remove_user_from_project(@author)

    Role.non_member_watcher
    Role.non_member_author
  end

  def login_watcher
    assert_equal 'rhill', @watcher.login
    log_user('rhill', 'foo')
  end

  def login_author
    assert_equal 'jsmith', @author.login
    log_user('jsmith', 'jsmith')
  end

  def remove_user_from_project(user)
    @project.memberships.where(:user_id => user.id).destroy_all
  end

end

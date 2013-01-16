require File.expand_path('../../../../test_helper', __FILE__)

class RolePatchTest < ActiveSupport::TestCase
  fixtures :roles

  def test_defined_new_visibility_option
    opts = Role::ISSUES_VISIBILITY_OPTIONS.map &:first
    assert_include 'watch', opts
  end

  def test_validate_new_visibility_option
    role = Role.non_member_watcher
    role.issues_visibility = 'watch'
    assert_true role.valid?
  end

  context "#non_member_watcher" do
    should "return the non-member-watcher role" do
      role = Role.non_member_watcher
      assert role.builtin?
      assert_equal Role::BUILTIN_NON_MEMBER_WATCHER, role.builtin
    end

    context "with a missing non-member-watcher role" do
      setup do
        Role.delete_all("builtin = #{Role::BUILTIN_NON_MEMBER_WATCHER}")
      end

      should "create a new non-member-watcher role" do
        assert_difference('Role.count') do
          Role.non_member_watcher
        end
      end

      should "return the non-member-watcher role" do
        role = Role.non_member_watcher
        assert role.builtin?
        assert_equal Role::BUILTIN_NON_MEMBER_WATCHER, role.builtin
      end
    end
  end

end


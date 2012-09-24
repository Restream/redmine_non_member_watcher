module RedmineNonMemberWatcher
  module DefaultData
    module Loader
      class << self
        def no_data?
          !Role.find(:first, :conditions => {
              :builtin => Role::BUILTIN_NON_MEMBER_WATCHER
          })
        end

        def load
          Role.non_member_watcher.update_attributes!(
              :permissions => [
                  :view_watched_issues,
                  :receive_email_notifications,
                  :edit_issues,
                  :add_issue_notes
              ],
              :issues_visibility => 'watch'
          )
        end
      end
    end
  end
end

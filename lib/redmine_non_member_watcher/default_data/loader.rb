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
          Role.non_member_watcher.update_attribute :permissions, [
              :view_issues,
              :receive_email_notifications
          ]
        end
      end
    end
  end
end

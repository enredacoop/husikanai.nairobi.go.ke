load Rails.root.join("app", "controllers", "polls_controller.rb")

class PollsController
  has_filters %w[upcoming current expired]
  before_action :default_to_current_filter, only: :index
  before_action :block_upcoming_poll, except: :index

  private

    def block_upcoming_poll
      return unless @poll.upcoming?

      redirect_to polls_path(filter: "upcoming"), alert: t("polls.upcoming.not_available")
    end

    def default_to_current_filter
      @current_filter = "current" if params[:filter].blank?
    end
end

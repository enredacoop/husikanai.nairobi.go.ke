load Rails.root.join("app", "models", "poll.rb")

class Poll
  scope :upcoming, -> { where(starts_at: Time.current..) }

  def upcoming?(timestamp = Time.current)
    starts_at > timestamp
  end
end

load Rails.root.join("app", "models", "progress_bar.rb")

class ProgressBar
  # The primary progress bar is shown in cached views of the progressable
  after_commit -> { progressable&.touch unless progressable&.destroyed? }
end

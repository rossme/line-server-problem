# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  if ENV["FILE_TO_PREPROCESS"].present?
    Rails.logger.info "`Please wait. Running PreprocessFileJob for file: #{ENV['FILE_TO_PREPROCESS']}"

    begin
      PreprocessFileJob.perform_now(ENV["FILE_TO_PREPROCESS"])
      Rails.logger.info "PreprocessFileJob completed successfully."
    rescue StandardError => e
      Rails.logger.error "Error running PreprocessFileJob: #{e.message}"
      raise
    end
  else
    Rails.logger.warn "FILENAME environment variable is not set. Skipping PreprocessFileJob."
    raise
  end
end

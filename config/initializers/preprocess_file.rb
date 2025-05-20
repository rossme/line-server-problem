# frozen_string_literal: true

unless Rails.env.test?
  # This initializer is used to run the PreprocessFileJob when the application is reloaded.
  # It checks if the FILENAME environment variable is set and runs the job with the specified file.
  # If the variable is not set, it raises an error and logs a warning.
  #
  # @example
  #   FILENAME=path/to/file.txt rails server
  #
  # @note This initialiser should not be used in test environments.

  Rails.application.reloader.to_prepare do
    if ENV["FILE_TO_PREPROCESS"].present?
      Rails.logger.info "Please wait. Running PreprocessFileJob for file: #{ENV['FILE_TO_PREPROCESS']}"

      begin
        PreprocessFileJob.perform_now(ENV["FILE_TO_PREPROCESS"])
        Rails.logger.info "PreprocessFileJob completed successfully. You can now access the application http://localhost:3000"
      rescue StandardError => e
        Rails.logger.error "Error running PreprocessFileJob: #{e.message}"
        raise
      end
    else
      Rails.logger.warn "FILENAME environment variable is not set. Skipping PreprocessFileJob."
    end
  end
end

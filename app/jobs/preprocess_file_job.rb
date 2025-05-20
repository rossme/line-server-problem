# frozen_string_literal: true

# This job is responsible for preprocessing a file.
# It uses the `PreprocessFile` service to handle the actual preprocessing logic.
# The job is queued in the default queue and logs a success message upon completion.
#
# @param [file_path] the path to the file to be preprocessed.
# @return [void]
#
# @example PreprocessFileJob.perform_now("path/to/file.txt")

class PreprocessFileJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    PreprocessFile.call(file_path)

    Rails.logger.info I18n.t("services.preprocess_file.job_success", file_path: file_path)
  end
end

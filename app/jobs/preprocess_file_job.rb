# frozen_string_literal: true

class PreprocessFileJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    PreprocessFile.call(file_path)

    Rails.logger.info I18n.t("services.preprocess_file.job_success", file_path: file_path)
  end
end

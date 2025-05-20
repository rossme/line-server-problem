# frozen_string_literal: true

module V1
  module Defaults
    extend ActiveSupport::Concern

    included do
      version "v1", using: :header, vendor: "salsify", format: :json

      helpers do
        def api_error!(error)
          status_code = fetch_status_code(error)
          error_message = error.message

          Rails.logger.info "[API Handled Error] #{status_code} | #{error_message}"

          error!(error_message, status_code)
        end

        private

        def fetch_status_code(error)
          case error
          when IndexError then 413
          when TypeError  then 400
          # Etc...
          else
            500
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Returns an HTTP status of 200 and the text of the requested line.
# Returns an HTTP status of 413 if the requested line is outside the bounds of the file.
# This endpoint is mounted in the `routes.rb` file.
#
# @param [index] the index of the line to retrieve.
# @example GET /lines/12345678

module V1
  class Lines < Grape::API
    include V1::Defaults

    format :json

    resource :lines do
      desc "GET /lines/<index>", {
        summary: "Retrieve a specific line by index",
        success: [
          { code: 200 }
        ],
        failure: [
          { code: 400 },
          { code: 413 }
        ]
      }
      params do
        requires :index, type: Integer, desc: "The index of the line to retrieve"
      end
      route_param :index do
        get do
          response = LineRetriever.call(params[:index])

          if response&.success?
            { line: response.object, status: 200 }
          else
            api_error!(response&.error || "Unexpected error")
          end
        end
      end
    end
  end
end

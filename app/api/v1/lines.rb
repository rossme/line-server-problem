# frozen_string_literal: true

# GET /lines/<index>
#   Returns an HTTP status of 200 and the text of the requested line or an HTTP 413 status if the requested line is beyond the end of the file.

module V1
  class Lines < Grape::API
    include V1::Defaults

    resource :lines do
      desc "GET /lines/<index>"
      params do
        requires :index, type: Integer, desc: "Line index"
      end
      route_param :index do
        get do
          response = LineRetriever.call(params[:index])

          if response&.success?
            present response.object
          else
            api_error!(response&.error || "Unexpected error")
          end
        end
      end
    end
  end
end

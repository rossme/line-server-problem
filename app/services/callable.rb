# frozen_string_literal: true

# This module is designed to be included in service classes that follow the
# command pattern. It provides a class method `call` that allows you to
# instantiate the service and call its `call` method in one step.
#
# Example:
#
#   class MyService
#     include Callable
#
#     def initialize(arg1, arg2)
#       @arg1 = arg1
#       @arg2 = arg2
#     end
#
#     def call
#       # Your service logic here
#     end
#   end
#
#   MyService.call(arg1, arg2)

module Callable
  extend ActiveSupport::Concern

  class_methods do
    def call(*args)
      new(*args).call
    end
  end
end

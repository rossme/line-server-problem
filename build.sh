#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -o errexit

REQUIRED_RUBY_VERSION="3.3.4"

echo "Starting build process for Rails 8 application..."

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
  echo "Ruby is not installed. Please install Ruby $REQUIRED_RUBY_VERSION."
  exit 1
fi

# Check if the correct Ruby version is installed
INSTALLED_RUBY_VERSION=$(ruby -v | awk '{print $2}')
if [ "$INSTALLED_RUBY_VERSION" != "$REQUIRED_RUBY_VERSION" ]; then
  echo "Ruby version $REQUIRED_RUBY_VERSION is required. Installed version is $INSTALLED_RUBY_VERSION."
  exit 1
fi

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
  echo "Bundler not found. Installing..."
  gem install bundler
fi

# Install or update gems
if [ ! -d vendor/bundle ]; then
  echo "Installing gems..."
  bundle install
else
  echo "Checking for gem updates..."
  bundle update --bundler
fi

echo "Build process complete."

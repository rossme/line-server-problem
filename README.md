# Line Server Problem

## Motivation

This project is one solution to the [Line Server Problem](https://salsify.github.io/line-server.html), where multiple clients
are waiting in line to be served by a limited number of servers. The goal is to
efficiently manage the queue and ensure that clients are served in a timely
manner. The project is implemented in Ruby on Rails and uses Redis for
queue management.

## Installation

#### Versions

- Ruby: 3.2.2
- Rails: 8.0.2

To set up the project, follow these steps:

#### Build

Run the following command to check if you have the required dependencies installed.
The `build.sh` script will check for the Ruby version and install the required gems.
It will also run the tests with `RSpec` to ensure everything is working correctly.

```bash
  ./build.sh
```

#### Run

You can then run the application using the following command.

```bash
  ./run.sh <file_path>
```

This will start the Rails server where a background worker `PreprocessFileJob` will preprocess the file during initialization.
Once the file is preprocessed, the server will be ready to serve requests.

```bash
  ./run.sh /path/to/file
```

The server will be available at `http://localhost:3000`. You can access the endpoints
in [Postman](https://www.postman.com/) or any other API testing tool. Please note that the indexing of the lines begins at `0`.

```json
  GET "/lines/<line_index>"
```
This will return the line at the specified index with the status code `200` if the line exists.:

```json
  {
    "line": "1: This is a sample ASCII line for testing purposes.",
    "status": 200
  }
```

If the line index is out of range, it will return the status code `413` with the following message:

```json
  {
    "error": "Requested line index is outside file bounds"
  }
```

### File Preprocessing

The `PreprocessFile` service efficiently preprocesses a large `.txt` file by creating an index of byte offsets
for each line without loading the entire file into memory.
It stores this index and relevant metadata in a series of binary files within a `/files_in_bytesize` directory,
split into batches of `100_000` offsets per file.

This enables faster and more memory-efficient access to specific lines with the exposed endpoint.
The service ensures any previous preprocessing output is removed before starting,
handles errors gracefully, and logs the entire process for visibility.

### Line Retrieval

The `LineRetriever` service retrieves a specific line from the preprocessed file using the byte offset index.
It reads the relevant binary file containing the index of byte offsets and uses the offset to seek directly to the line in the original file.
This approach minimizes memory usage and improves performance by avoiding the need to load the entire file into memory.

#### A note on Marshal

The `PreprocessFile` service uses `Marshal.dump` to serialize the index of byte offsets for each line.
I have not worked with `Marshal` before, so this was a nice learning experience. Perhaps it is not really needed,
but I thought it would be a good idea to use it to serialize the index of byte offsets for each line.

`Marshal` is a Ruby built-in module that provides a way to serialize and deserialize Ruby objects. It is used to convert
Ruby objects into a byte stream that can be stored in a file or sent over a network.

The `LineRetriever` service uses `Marshal.load` to deserialize the index of byte offsets for each line.

### Cache memory store

The application uses `Rails.cache` to store the relevant bytesize file. This means that if the endpoint is called
with an index range (within 100,000) that has already been processed, the application will not need to read the file again.
It will check the cache first and if the file is not in the cache, it will read the file and store it in the cache.

### Logging

The application uses `Rails.logger` to log the requests and responses. The logs are
stored in the `log/development.log` file. You can check the logs in the terminal and see the requests
and responses being processed by the server.

### Testing

The project uses [RSpec](https://rspec.info/) for testing. You can run the tests using the following command:

```bash
  rspec
```

The tests will also be run automatically when you run the `build.sh` script.
The tests are located in the `spec` directory and cover the main functionality of the application.

### Endpoints

The application provides the following endpoints:
- `GET /lines/<line_index>`: Returns the line at the specified index. The index param is
  required and should be a valid integer. The server will return the line if it exists,
  otherwise it will return a `413` status code with an error message.

Grape API is used to define the endpoints and handle the requests. The API is defined in the `app/api/v1/lines.rb` file.

### Libraries

- `rails`: Rails 8 web framework used for building the application.
- `redis`: The Redis client for Ruby, used for queue management.
- `rspec`: The testing framework used for writing and running tests.
- `falcon`: The fibre HTTP server used for serving the application (this replaces `puma` threads).
- `dotenv`: The gem used for loading environment variables from a `.env` file.
- `grape`: The API framework used for building the RESTful API.

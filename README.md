# Line Server Problem

## Motivation

This project is one solution to the [Line Server Problem](https://salsify.github.io/line-server.html).
A text file with a large number of lines is preprocessed; the goal is to create a server that can
efficiently retrieve specific lines from the file without loading the entire file into memory.

## Raspberry Pi & Cloudflare
If you would like to test the `GET /lines/<line_index>` endpoint remotely, I have a Raspberry Pi 5 with 16GB of RAM
running this project through a Cloudflare tunnel (if my Pi is powered on!)

You can find the `GET /lines/<line_index>` endpoint here:
- [lsp.run.foo/lines/<line_index>](https://lsp.run.foo/lines/1000)
- Please note that you may need to refresh the browser if Cloudflare/Pi are not behaving as expected.

Or alternatively you can run this project locally (see below).

## Installation

This project uses Ruby: 3.2.2 and Ruby on Rails: 8.0.2. To set up the project, follow these steps:

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
  ./run.sh /path/to/file
```

This will start the Rails server where a background worker `PreprocessFileJob` will preprocess the file during initialization.
Once the file is preprocessed, the server will be ready to serve requests.

The server is available at `http://localhost:3000`. You can access the endpoints
in [Postman](https://www.postman.com/) or any other API testing tool. Please note that the indexing of the lines begins at `0`.

```bash
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

## File Preprocessing

You can use these example files from Google Drive to test the application:
- [10MB .txt file](https://drive.google.com/file/d/14IfL9SaOG_ILZTcnmKjKh7vGKMH2WHnu/view?usp=drive_link)
- [1GB .txt file](https://drive.google.com/file/d/1v6E_Fnnd5flSZEOzXRgYszakNLihirtZ/view?usp=drive_link)
- [10GB .txt file](https://drive.google.com/file/d/1gE8qxFii838ELR1gAsK84iOl-XJLQf2_/view?usp=drive_link)

During preprocessing, the application will create a directory called `/files_in_bytesize` in the root of the project.
Depending on the size of the file, this directory will take up approximately 1/10 of the size of the original file.

- The 10MB file takes approximately 1MB of space in the `/files_in_bytesize` directory. Processing time is around 250ms.
- The 1GB file takes approximately 100MB of space in the `/files_in_bytesize` directory. Processing time is around 27500ms.
- The 10GB file takes approximately 1GB of space in the `/files_in_bytesize` directory. Processing time is around 250000ms.

The `PreprocessFile` service efficiently preprocesses a large `.txt` file by creating an index of byte offsets
for each line without loading the entire file into memory.
It stores this index and relevant metadata in a series of binary files within a `/files_in_bytesize` directory,
split into batches of `100_000` offsets per file.

This enables faster and more memory-efficient access to specific lines with the exposed endpoint.
The service ensures any previous preprocessing output is removed before starting,
handles errors gracefully, and logs the entire process for visibility.

## Line Retrieval

The `LineRetriever` service retrieves a specific line from the preprocessed file using the byte offset index.
It reads the relevant binary file containing the index of byte offsets and uses the offset to seek directly to the line in the original file.
This approach minimizes memory usage and improves performance by avoiding the need to load the entire file into memory.

### File modification validation

The `LineRetriever` service also validates that the original text file has not been modified since the file was preproccesed. If it was modified then an exception is raised.

## Marshal

I read this [AppSignal blog post](https://blog.appsignal.com/2019/03/26/object-marshalling-in-ruby.html) on using [Marshal](https://docs.ruby-lang.org/en/3.4/marshal_rdoc.html).

The `PreprocessFile` service uses `Marshal.dump` to serialize the index of byte offsets for each line.
I have not worked with `Marshal` before, so this was a nice learning experience. Perhaps it is not really needed,
but I thought it would be a good idea to use it to serialize the index of byte offsets for each line.

`Marshal` is a Ruby built-in module that provides a way to serialize and deserialize Ruby objects. It is used to convert
Ruby objects into a byte stream that can be stored in a file or sent over a network.

The `LineRetriever` service uses `Marshal.load` to deserialize the index of byte offsets for each line.

## Cache memory store

The application uses `Rails.cache` to store the relevant bytesize file. This means that if the endpoint is called
with an index range (within 100,000) that has already been processed, the application will not need to read the file again.
It will check the cache first and if the file is not in the cache, it will read the file and store it in the cache.

## File comments

There are extensive comments in the code to explain what each part of the code does.

## Falcon

The application uses `Falcon` as the HTTP server. Falcon is a fast, concurrent HTTP server for Ruby using fibres instead of threads.
I first read about using `falcon` in Vladimir Dementyev's book [Layered Design for Ruby on Rails Applications](https://www.amazon.com/Layered-Design-Ruby-Rails-Applications/dp/1801813787)
and I thought it would be a good idea to try it out. It is a great alternative to `puma` but
I would need to implement this further to see how it performs in the real world. For example we would probably need to
use the gem `async-http` to make it work with `falcon` as the HTTP client.

## Logging

The application uses `Rails.logger` to log the requests and responses. The logs are
stored in the `log/development.log` file. You can check the logs in the terminal and see the requests
and responses being processed by the server.

## Testing

The project uses [RSpec](https://rspec.info/) for testing. You can run the tests using the following command:

```bash
  rspec
```

The tests will also be run automatically when you run the `build.sh` script.
The tests are located in the `spec` directory and cover the main functionality of the application.

## Endpoints

The application provides the following endpoints:
- `GET /lines/<line_index>`: Returns the line at the specified index. The index param is
  required and should be a valid integer. The server will return the line if it exists,
  otherwise it will return a `413` status code with an error message.

- This endpoint is fast and responds in around 15-20ms.

[Grape API](https://github.com/ruby-grape/grape) is used to define the endpoints and handle the requests. The API is defined in the `app/api/v1/lines.rb` file.

## Libraries

- `rails`: Rails 8 web framework used for building the application.
- `redis`: The Redis client for Ruby, used for queue management.
- `rspec`: The testing framework used for writing and running tests.
- `falcon`: The fibre HTTP server used for serving the application (this replaces `puma` threads).
- `dotenv`: The gem used for loading environment variables from a `.env` file.
- `grape`: The API framework used for building the RESTful API.

## A note on Bash and GPT 4o

I used `bash` to write the `build.sh` and `run.sh` scripts. I have not worked with `bash` before,
so this was a nice learning experience. Disclaimer - I used `GPT 4o` to help me write the scripts.

## Critique and notes on this exercise

Firstly, this was a really fun project to work on. I learned a lot more about Ruby, Marshal, and File I/O.
I also learned a lot about how to use `Rails.cache` and `Falcon`.

I am not sure if the `PreprocessFile` service is the best way to preprocess the file or if there is a better way to do it.
One alternative approach could be to use a database to store the lines and their offsets, this would be much more efficient
but a lot less interesting.

I think the current approach is a good balance between performance and simplicity.
And it certainly gives us something to discuss...

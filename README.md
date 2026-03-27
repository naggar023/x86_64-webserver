# x86_64-webserver

A minimal HTTP/1.0 web server written entirely in **x86_64 Linux assembly** (GAS, Intel syntax). It uses raw Linux syscalls with no libc or external dependencies, making it a great example of how a networked server works at the lowest level.

---

## Features

- Listens on **port 80** for incoming HTTP connections
- **Forks** a new child process to handle each accepted connection concurrently
- **GET requests** — serves a file whose path is taken directly from the request URI
- **POST requests** — creates (or overwrites) a file at the request URI path and writes the request body into it
- Responds with a bare `HTTP/1.0 200 OK` header followed by the file contents
- Zero runtime dependencies — only Linux kernel syscalls

---

## Prerequisites

- Linux x86_64
- GNU Binutils (`as`, `ld`)
- Root privileges (or `CAP_NET_BIND_SERVICE`) to bind to port 80

---

## Build

Assemble and link with the GNU toolchain:

```bash
as -o webserver.o webserver.s
ld -o webserver webserver.o
```

---

## Run

Because the server binds to the privileged port 80, it must be started as root (or with the appropriate capability):

```bash
sudo ./webserver
```

The server will start listening silently. Send requests with `curl` or any HTTP client:

```bash
# Serve an existing file
echo "Hello, world!" > index.html
curl http://localhost/index.html

# Create / overwrite a file via POST
curl -X POST http://localhost/hello.txt --data "Hello from POST"
```

> **Note:** To run without root, grant the binary the `CAP_NET_BIND_SERVICE` capability:
> ```bash
> sudo setcap 'cap_net_bind_service=+ep' ./webserver
> ./webserver
> ```

---

## How It Works

The server is implemented using the following Linux syscalls (numbers refer to the x86_64 ABI):

| Syscall | Number | Purpose |
|---------|--------|---------|
| `socket` | 41 | Create a TCP socket (`AF_INET`, `SOCK_STREAM`) |
| `bind` | 49 | Bind the socket to `0.0.0.0:80` |
| `listen` | 50 | Mark the socket as passive (listening) |
| `accept` | 43 | Block until a client connects, return a new fd |
| `fork` | 57 | Spawn a child process for the connection |
| `read` | 0 | Read the HTTP request from the client socket |
| `open` | 2 | Open (GET) or create (POST) the target file |
| `write` | 1 | Write the HTTP response and file content to the socket |
| `close` | 3 | Close file descriptors |
| `exit` | 60 | Terminate the process |

### Request lifecycle

1. **Parent process** calls `accept` in a loop. For each new client connection it calls `fork`.
2. **Child process** reads the raw HTTP request into a 1 KB buffer.
   - **GET**: Extracts the URI path, opens the corresponding file, sends `HTTP/1.0 200 OK\r\n\r\n` followed by the file contents, then exits.
   - **POST**: Extracts the URI path, creates the file, writes the request body (the portion after the last `\n`) into it, sends `HTTP/1.0 200 OK\r\n\r\n`, then exits.
3. **Parent process** closes the client socket fd and loops back to `accept`.

---

## Project Structure

```
webserver.s   — Full assembly source (GAS, Intel syntax)
README.md     — This file
```

---

## Limitations

- Only a `200 OK` response is ever sent; there is no error handling (missing files, bad requests, etc.)
- The request buffer is fixed at 1 KB; larger requests will be silently truncated
- No TLS/HTTPS support
- File paths in the URI are used directly without sanitisation — this server is **vulnerable to directory traversal attacks** and must not be exposed to untrusted networks

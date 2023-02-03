Pure-dart example of using Shorebird to create a simple post and watch RPC
with a custom type.

# Usage

```bash
shorebird run
```

# Notes
- Client never exits until the socket times out (unclear why).
- Server gets upset (SocketException: Write failed) when client re-connects.
  I think this is due to one of the Streams not forwarding a close message.
- Client never gets an echo for the 5th message.
- Client does not know how to disconnect on idle or reconnect with backoff.
- Need to test nullable argument types (not yet supported due to ignoring
  nullable types in the generator).
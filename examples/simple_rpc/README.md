Pure-dart example of using shorebird to create a simple post and watch RPC
with a custom type.

# Notes
- Works, but has lots of manual code instead of generated.
- Client never exits (unclear why).
- Server gets upset (SocketException: Write failed) when client re-connects.
- Client never gets an echo for the 5th message.
- Client does not know how to disconnect on idle or reconnect with backoff.
- Should test multiple arguments, optional, named, etc.
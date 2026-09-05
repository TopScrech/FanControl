# Component 1.11 restoration recovery

The installer previously probed the helper and then reused that connection for update preparation
An unsuccessful probe can leave the XPC connection invalid, so restoration can fail with NSCocoaErrorDomain 4099 even after the helper becomes available

Component 1.11 uses a separate authenticated connection for each restoration attempt
It retries connection interruption/invalidation errors up to four times with 500 ms between attempts
Each XPC request retains its existing five-second deadline
Hardware errors, signature errors, cancellation and exhausted retries still prevent unregistering or replacing an enabled helper
The protocol remains version 1 and the component build number remains 0

23 hardware-free tests pass, including:

- A transient invalid connection recovers before unregistering
- An unreachable enabled helper exhausts retries without unregistering
- A hardware restoration failure propagates immediately
- Cancellation during retry prevents subsequent attempts

At investigation time, launchctl reported the user's helper running
The original failure was not captured live, so this change addresses the identified invalid-connection reuse path without claiming every 4099 error has the same cause

The new test package is signed and notarized separately from the earlier 1.10 artifact
Installation on the user's Mac is left for their next test

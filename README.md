Unix Process Supervisor
=======================

This project exposes a single gen_server, `unixsup_worker`, which
allows you to have a unix process as a supervised child process.

Unix processes need to have the following requirements:

- do not put themselves in the background (e.g. a "nodaemon" option)
- exit the process when the standard input file descriptor is closed.


Author:
Arjan Scherpenisse <arjan@miraclethings.nl>

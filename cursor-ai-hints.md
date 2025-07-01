# Cursor AI hints

- When you edit markdown, stick to the format style that the files already have

- tag the versions without a "v" prefix

- We have three run modes

  - **Test-mode**: When started on the local development computer on which cursor-ai runs
  - **Github-Mode**: When Run by Github actions
  - **Addon-Mode**: When run as a home Assistant Add-On

- The add-on must run equally well in all run modes

- All waits must be loops that have a minimal fixed time (0.5 seconds) and then check what they are waiting for

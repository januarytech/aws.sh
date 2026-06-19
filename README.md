# aws.sh

[![No Maintenance Intended](https://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

This repository contains scripts to start a shell with elevated AWS credentials. The script is particularly nice because it will tweak your _existing_ shell prompt to say `[PROD AWS SHELL]`, while preserving your theme (for most shell themes - shell themes that dynamically rewrite prompt variables will not work). This shell prompt injection stuff is the main bit of code that's actually interesting in this repository, the rest is just AWS CLI wrapper code basically.

This project is provided because the code is useful, but it is not a complete project that can be reused off the shelf. It will need significant adapting to your environment. This codebase is a sanitized version of what we at January have developed internally. In particular:

* Commit messages have been rewritten to remove environment-specific references
* Commit diffs have been rewritten to remove code that only makes sense in our environment, and probably leaks details about our environment
* Many newer commits have been left out, because they leak details about our environment and because they don't touch the shell prompt injection code, which is the really interesting bits here anyway

## License

MIT

## Authors

Various employees of January Technologies, Inc.

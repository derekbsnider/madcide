# Security Policy

## Supported versions

Security fixes land in the next release; only the latest release, with
the madc release it carries, is supported.

| Version          | Supported |
|------------------|-----------|
| latest release   | yes       |
| earlier releases | no        |

## Reporting a vulnerability

Please report a vulnerability privately, not in a public issue:

1. Open the repository's **Security** tab.
2. Choose **Report a vulnerability**.
3. Describe the problem: the madcide version (Help ▸ About, or the
   package's name), the platform, whether it was the terminal or the
   window, and the steps that show it.

A confirmed vulnerability is fixed in the next release, and the release
notes credit the reporter unless they ask otherwise.

## Scope

madcide runs the code you write — Run, the REPL, a terminal — and the
plugins you install, with your rights. That is what it is for, so it is
not a vulnerability in itself.

In scope:

- opening or editing a file running code you did not ask to run;
- madcide loading plugins, key profiles or other code from the directory
  it is started in, rather than from its installation or your own
  configuration;
- the window (its web page) reaching files, programs or the network
  beyond what you asked of the IDE;
- an installed package (`.deb`, `.rpm`, tarball, zip) that installs files
  with unsafe permissions or outside the places it names.

A flaw in madc itself (the compiler madcide carries) belongs in
[madc's repository](https://github.com/derekbsnider/madc); report it there.

# Debian package prototype for google-cloud-cpp

This repository contains a proof of concept for packaging `google-cloud-cpp`.

It contains a Dockerfile that produces a debian package for `google-cloud-cpp`.
It installs the package. It builds a quickstart (which uses a C++ GCS client) to
verify the install.

To try it out for yourself:

```sh
docker build -t package-builder .
```

## Notes

- Support needed in `google-cloud-cpp`:
  - Configure using standalone crc32c vs. Abseil's crc32c in storage
- Open questions:
  - What gets installed? mocks? every library?
  - Maybe we want like: `libgoogle-cloud-cpp-dev`, `libgoogle-cloud-cpp-core`
    where `-dev` has all libraries, `-core` has only the most used libraries.
  - Do we want a runtime package? eh.

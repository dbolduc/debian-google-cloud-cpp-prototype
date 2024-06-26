# Debian package prototype for google-cloud-cpp

This repository contains a proof of concept for packaging `google-cloud-cpp`.

It contains a Dockerfile that produces a debian package and a Dockerfile to test
the package that is produced.

To try it out for yourself:

```sh
./run.sh
```

## Notes

- There is no Debian `rules` file. I was building with CMake. I will need help
  from a Debian maintainer on this part.
- The architecture is hardcoded to `x86_64-linux-gnu`.
- Support needed in `google-cloud-cpp`:
  - Configure using standalone crc32c vs. Abseil's crc32c in storage
  - Configurable install directories for...
    - headers
    - cmake
    - pkgconfig
- Open questions:
  - What gets installed? mocks? every library?
  - Maybe we want like: `libgoogle-cloud-cpp-devel`, `libgoogle-cloud-cpp-core`
    where `-devel` has all libraries, `-core` has only the most used libraries.
  - Do we want a runtime package? eh.

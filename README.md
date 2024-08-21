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

- We have to split the packages. Manually segregating the headers that belong to
  a given library is doable, but kind of annoying. It might be easiest to have
  one google-cloud-cpp-common which includes all of `common`, `grpc-utils`,
  `rest_internal`, `rest_protobuf_internal`. (Because then we can just say
  `usr/include/google/cloud/*.h` + `usr/include/google/cloud/internal/*.h`)
  - Still it feels like there should be a better way. I have to ask. When we
    install the components it knows all of the headers, libs, cmake, pkgconfig
    files. Can we teach that to the package builder?
  - Proto libraries will need to know their paths (which is not necessarily
    google/cloud/foo). And I seriously worry about conflicts here...
    - e.g. bigquery... and bigquerycontrol would have to be done separate.
    - e.g. iam... which is a library, and included in common.

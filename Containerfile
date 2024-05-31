ARG REGISTRY=docker.io
ARG ALPINE_VER=3.20.0@sha256:77726ef6b57ddf65bb551896826ec38bc3e53f75cdde31354fbffb4f25238ebd
ARG GO_VER=1.22.3-alpine@sha256:b8ded51bad03238f67994d0a6b88680609b392db04312f60c23358cc878d4902
ARG ECR_HELPER_VER=0fe7eafab21668ab8d04f0246d88e4dd6c305114
ARG GCR_HELPER_VER=v2.1.22

FROM registry.access.redhat.com/ubi9/ubi:latest@sha256:66233eebd72bb5baa25190d4f55e1dc3fff3a9b77186c1f91a0abdb274452072 as golang
RUN dnf -y install git make golang
RUN \
  groupadd -g 1000 appuser; \
  useradd -u 1000 -g appuser -s /bin/sh -d /home/appuser appuser && \
  mkdir -p /home/appuser/.regctl && \
  chown -R appuser /home/appuser/.regctl
WORKDIR /src

FROM golang as build
COPY regclient/go.* /src/
RUN go mod download
COPY regclient/. /src/
RUN make bin/regctl
USER appuser
CMD [ "bin/regctl" ]

FROM registry.access.redhat.com/ubi9/ubi:latest@sha256:66233eebd72bb5baa25190d4f55e1dc3fff3a9b77186c1f91a0abdb274452072
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build --chown=appuser /home/appuser /home/appuser
COPY --from=build /src/bin/regctl /usr/local/bin/regctl
USER appuser
CMD [ "regctl", "--help" ]

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_VERSION=(devel)
LABEL maintainer="" \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.authors="regclient contributors" \
      org.opencontainers.image.url="https://github.com/konflux-ci/regctl-container" \
      org.opencontainers.image.documentation="https://github.com/konflux-ci/regctl-container" \
      org.opencontainers.image.source="https://github.com/konflux-ci/regctl-container" \
      org.opencontainers.image.version=$VCS_VERSION \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.vendor="regclient" \
      org.opencontainers.image.licenses="Apache 2.0" \
      org.opencontainers.image.title="regctl" \
      org.opencontainers.image.description="regclient/regctl CLI for managing registry content (ubi)"

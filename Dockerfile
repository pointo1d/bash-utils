FROM buildpack-deps
RUN apt-get update && apt-get install -y git
COPY --from=shellspec/shellspec-scratch /opt/shellspec /opt/shellspec
ENV PATH=/opt/shellspec/:$PATH
WORKDIR /src
ENTRYPOINT [ "shellspec" ]
LABEL Description="bash-utils docker test image "
COPY ./ /src

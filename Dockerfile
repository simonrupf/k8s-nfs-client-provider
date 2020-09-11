# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.15.2-alpine3.12
RUN apk add git
USER 1000:1000
ENV GOCACHE /go/.cache
ENV CGO_ENABLED 0
COPY cmd /go/src/cmd
WORKDIR /go/src/cmd
# workaround as the k8s.io/klog redirect currently fails
RUN go get -d github.com/kubernetes/klog && mv /go/src/github.com/kubernetes /go/src/k8s.io
# recursively get dependencies
RUN go get -d ./...
RUN go build -a -ldflags '-extldflags "-static" -s -w' -o /go/nfs-client-provisioner ./...
RUN apk add upx && upx --ultra-brute /go/nfs-client-provisioner || true

FROM scratch
COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=0 /go/nfs-client-provisioner /bin/nfs-client-provisioner
USER 255:255
ENTRYPOINT ["/bin/nfs-client-provisioner"]

all: package-scanner

.PHONY: bootstrap
bootstrap: vendor
	$(PWD)/bootstrap.sh

.PHONY: clean
clean:
	-rm package-scanner

.PHONY: vendor
vendor:
	go mod tidy -v
	go mod vendor

package-scanner: vendor $(PWD)/**/*.go $(PWD)/agent-plugins-grpc/**/*.go
	CGO_ENABLED=0 go build -buildvcs=false -v .

.PHONY: docker
docker:
	docker build -t toaeio/toae_package_scanner:latest .

.PHONY: docker-multi-arch
docker-multi-arch:
	docker buildx build --platform linux/arm64,linux/amd64 --tag toaeio/toae_package_scanner:latest .

.PHONY: buildx
buildx:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name builder --driver docker-container --driver-opt network=host --use
	docker buildx ls
	docker buildx inspect --bootstrap

.PHONY: rm-buildx
rm-buildx:
	docker buildx rm builder

.PHONY: tools
tools: grype syft

.PHONY: grype
grype: 
	(cd tools/grype-bin && ./get_grype.sh)

.PHONY: syft
syft: 
	(cd tools/syft-bin && ./get_syft.sh)

.PHONY: install-goreleaser
install-goreleaser:
	go install github.com/goreleaser/goreleaser@latest

.PHONY: release
release: install-goreleaser
	goreleaser release --snapshot --clean

.PHONY: update-sdk
update-sdk:
	go get -u -v github.com/Sam12121/golang_toae_sdk/client@latest
	go get -u -v github.com/Sam12121/golang_toae_sdk/utils@latest

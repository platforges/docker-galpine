ALPINE_VERSION ?= latest
IMAGE ?= ghcr.io/platforges/galpine
PLATFORM ?= linux/amd64

.PHONY: all build test
all: build test

build:
	docker build --platform $(PLATFORM) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(IMAGE):$(ALPINE_VERSION) .

test:
	docker run --rm -i --platform $(PLATFORM) $(IMAGE):$(ALPINE_VERSION) sh < test.sh

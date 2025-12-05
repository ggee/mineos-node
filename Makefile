REGISTRY_NAME := docker.io/
REPOSITORY_NAME := greggee/
IMAGE_NAME := mineos
TAG := :latest
BUILD_TAG := :java21
PLATFORMS := linux/arm64
#PLATFORMS := linux/amd64,linux/arm/v7,linux/arm64

.PHONY: getcommitid
all: build

getcommitid: 
	$(eval COMMITID = $(shell git log -1 --pretty=format:"%H"))

build: getcommitid
	@podman build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	@podman build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .
	@podman build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG) -f Dockerfile .

publishcommit: build
	podman login
	podman push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID)
	podman logout

publish: build
	podman login
	podman push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	podman push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG)
	podman push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID)
	podman logout

build-multiarch: getcommitid
	@docker buildx build --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	@docker buildx build --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG) -f Dockerfile .
	@docker buildx build --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .

publish-multiarch: build-multiarch
	docker login
	docker buildx build --push --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG) -f Dockerfile .
	docker buildx build --push --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .
	docker buildx build --push --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	docker logout

clean-multiarch:
	docker buildx prune -f



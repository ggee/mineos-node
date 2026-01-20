REGISTRY_NAME := docker.io/
REPOSITORY_NAME := greggee/
IMAGE_NAME := mineos
TAG := :latest
#PLATFORMS := linux/arm64
PLATFORMS := linux/amd64,linux/arm/v7,linux/arm64

.PHONY: getcommitid
all: build

getcommitid: 
	$(eval COMMITID = $(shell git log -1 --pretty=format:"%H"))

build: getcommitid
	@docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	@docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .

publishcommit: build
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID)

publish: build
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG)
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID)

build-multiarch: getcommitid
	@docker buildx build --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	@docker buildx build --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .

publish-multiarch: build-multiarch
	docker buildx build --push --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	docker buildx build --push --platform $(PLATFORMS) --tag $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .

clean-multiarch:
	docker buildx prune -f



REGISTRY_NAME := 
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
	@docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) -f Dockerfile .
	@docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -f Dockerfile .
	@docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG) -f Dockerfile .

publishcommit: build
	docker login
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID)
	docker logout

publish: build
	docker login
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(BUILD_TAG)
	docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID)
	docker logout

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



tag_docker ?= latest
build_docker: Dockerfile
	docker build -t beyondpie/rstudio:$(tag_docker) .
	docker push beyondpie/rstudio:$(tag_docker)

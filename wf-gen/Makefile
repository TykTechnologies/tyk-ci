# This makefile uses relative paths, make sure you are in the correct directory

BRANCH := $(shell git branch --show-current)

# Relies on targets having 3 dirs in their path
root-path = $(dir $(dir $(dir $1)))

# targets := .github/workflows/int-image.yml integration/terraform/outputs.tf integration/image/Dockerfile 
# gen-targets = $(addprefix $1/,$(targets))

define git-pull =
mkdir -p $(dir $@)
(cd $(call root-path,$@); git checkout -q $(BRANCH) && git pull -q)
endef

define git-push-origin =
(cd $1; git diff; read -p "Diff in $1 repo. C-c to cancel." c; \
git diff -q && git add . && git commit -m "Syncing integration workflow from tyk-ci"; git push origin $(BRANCH))
endef

.PHONY: tyk tyk-analytics tyk-pump local external

all: local external

local: ../cfssl/outputs.tf ../.github/workflows/cfssl.yml ../int-service/outputs.tf ../.github/workflows/int-service.yml

external: tyk tyk-analytics tyk-pump

tyk: tyk/.github/workflows/int-image.yml tyk/integration/terraform/outputs.tf tyk/integration/image/Dockerfile
	$(call git-push-origin,tyk-analytics)

tyk-analytics: tyk-analytics/.github/workflows/int-image.yml tyk-analytics/integration/terraform/outputs.tf tyk-analytics/integration/image/Dockerfile
	$(call git-push-origin,tyk-analytics)

tyk-pump: tyk-pump/.github/workflows/int-image.yml tyk-pump/integration/terraform/outputs.tf tyk-pump/integration/image/Dockerfile
	$(call git-push-origin,tyk-pump)

../cfssl/outputs.tf: output.tf.m4
	m4 -DxREPO=cfssl $< > $@

../.github/workflows/cfssl.yml: int-image.yml.m4
	m4 -DxREPO=cfssl -DxPATH_TRIGGERED $< > $@

../int-service/outputs.tf: output.tf.m4
	m4 -DxREPO=int-service $< > $@

../.github/workflows/int-service.yml: int-image.yml.m4
	m4 -DxREPO=int-service -DxPATH_TRIGGERED=true $< > $@

tyk/.github/workflows/int-image.yml: int-image.yml.m4
	$(git-pull)
	m4 -DxREPO=tyk -DxREPO_DIR=integration/image \
	   -DxTF_DIR=integration/terraform -DxRELEASE_BRANCHES $< > $@

tyk/integration/terraform/outputs.tf: output.tf.m4
	$(git-pull)
	mkdir -p $(dir $@)
	m4 -DxREPO=tyk $< > $@

tyk/integration/image/Dockerfile: Dockerfile.m4
	$(git-pull)
	mkdir -p $(dir $@)
	m4 -DxREPO=tyk $< > $@

tyk-analytics/.github/workflows/int-image.yml: int-image.yml.m4
	$(git-pull)
	m4 -DxREPO=tyk-analytics -DxREPO_DIR=integration/image \
	   -DxTF_DIR=integration/terraform -DxRELEASE_BRANCHES $< > $@

tyk-analytics/integration/terraform/outputs.tf: output.tf.m4
	$(git-pull)
	m4 -DxREPO=tyk-analytics $< > $@

tyk-analytics/integration/image/Dockerfile: Dockerfile.m4
	$(git-pull)
	mkdir -p $(dir $@)
	m4 -DxREPO=tyk-analytics $< > $@

tyk-pump/.github/workflows/int-image.yml: int-image.yml.m4
	$(git-pull)
	m4 -DxREPO=tyk-pump -DxREPO_DIR=integration/image \
	   -DxTF_DIR=integration/terraform -DxRELEASE_BRANCHES $< > $@

tyk-pump/integration/terraform/outputs.tf: output.tf.m4
	$(git-pull)
	m4 -DxREPO=tyk-pump $< > $@

tyk-pump/integration/image/Dockerfile: Dockerfile.m4
	$(git-pull)
	mkdir -p $(dir $@)
	m4 -DxREPO=tyk-pump $< > $@

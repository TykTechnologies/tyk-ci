# This makefile uses relative paths, make sure you are in the correct directory

cfssl:
	m4 -DxREPO=$@ templates/output.tf.m4 > ../$(@)/outputs.tf
	m4 -DxREPO=$@ -DxPATH_TRIGGERED=true templates/int-image.yml.m4 > ../.github/workflows/$(@).yml

int-service:
	m4 -DxREPO=$@ templates/output.tf.m4 > ../$(@)/outputs.tf
	m4 -DxREPO=$@ -DxPATH_TRIGGERED=true templates/int-image.yml.m4 > ../.github/workflows/$(@).yml

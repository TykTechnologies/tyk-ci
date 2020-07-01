# This makefile uses relative paths, make sure you are in the correct directory

local: ../cfssl/outputs.tf ../.github/workflows/cfssl.yml ../int-service/outputs.tf ../.github/workflows/int-service.yml

external:

../cfssl/outputs.tf: output.tf.m4
	m4 -DxREPO=cfssl $< > $@

../.github/workflows/cfssl.yml: int-image.yml.m4
	m4 -DxREPO=cfssl -DxPATH_TRIGGERED=true $< > $@

../int-service/outputs.tf: output.tf.m4
	m4 -DxREPO=int-service $< > $@

../.github/workflows/int-service.yml: int-image.yml.m4
	m4 -DxREPO=int-service -DxPATH_TRIGGERED=true $< > $@

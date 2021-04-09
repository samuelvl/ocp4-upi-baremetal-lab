# Terraform parameters
ENVIRONMENT       := lab
TERRAFORM         := terraform
TF_FILES_PATH     := src
TF_BACKEND_CONF   := configuration/backend
TF_VARIABLES      := configuration/tfvars
LIBVIRT_IMGS_PATH := images
OCP_VERSION       := 4.6.8
OCP_RELEASE       := $(shell echo $(OCP_VERSION) | head -c 3)
OCP_INSTALLER     := openshift-install
RHCOS_VERSION     := 4.6.8
RHCOS_IMAGE_PATH  := $(LIBVIRT_IMGS_PATH)/rhcos-${RHCOS_VERSION}-x86_64-qemu.x86_64.qcow2
FCOS_VERSION      := 32.20200629.3.0
FCOS_IMAGE_PATH   := $(LIBVIRT_IMGS_PATH)/fedora-coreos-$(FCOS_VERSION).x86_64.qcow2

all: init deploy test

require:
	$(info Installing dependencies...)
	@./requirements.sh

download-images:
	mkdir -p $(LIBVIRT_IMGS_PATH)

ifeq (,$(wildcard $(RHCOS_IMAGE_PATH)))
	$(info Downloading Red Hat CoreOS image...)
	curl -L -f -o $(RHCOS_IMAGE_PATH).gz \
		https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_RELEASE}/${RHCOS_VERSION}/rhcos-${RHCOS_VERSION}-x86_64-qemu.x86_64.qcow2.gz

	gunzip -c $(RHCOS_IMAGE_PATH).gz > $(RHCOS_IMAGE_PATH)

	$(RM) -f $(RHCOS_IMAGE_PATH).gz
else
	$(info Red Hat CoreOS image already exists)
endif

ifeq (,$(wildcard $(FCOS_IMAGE_PATH)))
	$(info Downloading Fedora CoreOS image...)
	curl -L -f -o $(FCOS_IMAGE_PATH).xz \
		https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$(FCOS_VERSION)/x86_64/fedora-coreos-$(FCOS_VERSION)-qemu.x86_64.qcow2.xz

	unxz -c $(FCOS_IMAGE_PATH).xz > $(FCOS_IMAGE_PATH)

	$(RM) -f $(FCOS_IMAGE_PATH).xz
else
	$(info Fedora CoreOS image already exists)
endif

download-installer:
	$(info Downloading Openshift installer...)
ifeq (,$(wildcard $(OCP_INSTALLER)))
	@wget -O $(OCP_INSTALLER)-linux.tar.gz \
		https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(OCP_VERSION)/openshift-install-linux.tar.gz
	@tar -xvf $(OCP_INSTALLER)-linux.tar.gz $(OCP_INSTALLER)
	$(RM) -f $(OCP_INSTALLER)-linux.tar.gz
endif

setup-dns:
	$(info Elevating privileges...)
	@sudo -v

	$(info Configuring dnsmasq...)
	@sudo chmod 777 /etc/NetworkManager/conf.d
	@sudo chmod 777 /etc/NetworkManager/dnsmasq.d

init: download-images download-installer setup-dns
	$(info Initializing Terraform...)
	$(TERRAFORM) init \
		-backend-config="$(TF_BACKEND_CONF)/$(ENVIRONMENT).conf" $(TF_FILES_PATH)

changes:
	$(info Get changes in infrastructure resources...)
	$(TERRAFORM) plan \
		-var=OCP_VERSION=$(OCP_VERSION) \
		-var=OCP_ENVIRONMENT=$(ENVIRONMENT) \
		-var-file="$(TF_VARIABLES)/default.tfvars" \
		-var-file="$(TF_VARIABLES)/$(ENVIRONMENT).tfvars" \
		-out "output/tf.$(ENVIRONMENT).plan" \
		$(TF_FILES_PATH)

deploy: changes
	$(info Deploying infrastructure...)
	$(TERRAFORM) apply output/tf.$(ENVIRONMENT).plan

test:
	$(info Testing infrastructure...)

clean-installer:
	$(info Deleting Openshift installation files...)
	$(RM) openshift-install

clean-olm:
	$(info Deleting OLM catalog files...)
	$(RM) -r day-two/02-olm/catalogs

clean-dns:
	$(info Elevating privileges...)
	@sudo -v

	$(info Restoring network configuration...)
	@sudo chmod 755 /etc/NetworkManager/conf.d
	@sudo chmod 755 /etc/NetworkManager/dnsmasq.d
	@sudo systemctl restart NetworkManager

clean-infra:
	$(info Destroying infrastructure...)
	$(TERRAFORM) destroy \
		-auto-approve \
		-var=OCP_VERSION=$(OCP_VERSION) \
		-var=OCP_ENVIRONMENT=$(ENVIRONMENT) \
		-var-file="$(TF_VARIABLES)/default.tfvars" \
		-var-file="$(TF_VARIABLES)/$(ENVIRONMENT).tfvars" \
		$(TF_FILES_PATH)
	$(RM) -r .terraform
	$(RM) -r output/tf.$(ENVIRONMENT).plan
	$(RM) -r output/openshift-install/$(ENVIRONMENT)
	$(RM) -r output/mirror/$(ENVIRONMENT)
	$(RM) -r state/terraform.$(ENVIRONMENT).tfstate

clean: changes clean-installer clean-olm clean-dns clean-infra

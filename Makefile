BUILD_DIR := output
IMAGE_NAME := autosd
IMAGE_TAG := bifrost-minimal

.PHONY: build run clean

build:
	mkdir -p $(BUILD_DIR)
	podman run --rm -it \
		--privileged \
	    	--pull=newer \
	    	--security-opt label=type:unconfined_t \
	    	-v $(pwd)/config.json:/config.json \
	    	-v $(pwd)/output:/output \
	    	quay.io/centos-bootc/bootc-image-builder:latest \
	    	--type qcow2 \
	    	--config /config.json \
		quay.io/automotive-toolchain/$(IMAGE_NAME):$(IMAGE_TAG)

run:
	qemu-system-x86_64 \
		-drive file=/usr/share/OVMF/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
		-drive file=/usr/share/OVMF/OVMF_VARS.fd,if=pflash,format=raw,unit=1,snapshot=on,readonly=off \
		-smp 12 \
		-enable-kvm \
		-m 2G \
		-machine q35 \
		-cpu host \
		-device virtio-net-pci,netdev=n0,mac=FE:14:87:3f:ca:29 \
		-netdev user,id=n0,net=10.0.2.0/24,hostfwd=tcp::2222-:22 \
		-drive file=$(BUILD_DIR)/qcow2/disk.qcow2,index=0,media=disk,format=qcow2,if=virtio,snapshot=off

clean:
	rm -rf $(BUILD_DIR)



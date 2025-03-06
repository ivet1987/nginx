# login to registry.stage
sudo podman login registry.stage.redhat.io

# build image from Containerfile
sudo podman build --tag nginx-test .

# get bootc-image-builder
sudo podman pull registry.stage.redhat.io/rhel10/bootc-image-builder:10.0

# create disk image
mkdir output
sudo podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t -v ./output:/output -v /var/lib/containers/storage:/var/lib/containers/storage registry.stage.redhat.io/rhel10/bootc-image-builder:10.0 --type qcow2 --use-librepo=True localhost/nginx-test:latest

# run testing on image
tmt --context "distro=rhel-10.0 product=rhel arch=x86_64" run -a provision -h virtual --image /home/bnater/git/gitlab.com/rhel/tests/nginx/bootc/output/qcow2/disk.qcow2 tests --filter 'tier:1&component:nginx' plans --name all-non-buildroot report --how reportportal --project baseosqe --launch image-mode-nginx-tier1

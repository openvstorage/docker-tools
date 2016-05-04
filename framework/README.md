Work in progress -- dockerised framework

docker build -t framework .

weave launch --ipalloc-range 10.250.0.0/24
./setup_fwknode.sh fwk1 10.250.0.1/24

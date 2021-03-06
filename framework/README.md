Work in progress -- dockerised framework

docker build -t framework .

On first node:

    weave launch --ipalloc-range 10.250.0.0/24
    ./setup_fwknode.sh fwk1 10.250.0.1/24

On second node:

    weave launch --ipalloc-range 10.250.0.0/24 <PUBLIC_IP_OF_FIRST_HOST>
    ./setup_fwknode.sh fwk2 10.250.0.2/24 10.250.0.1

WORKING:
- GUI 
- all required services (etcd/memcache/nginx/rabbitmq/celery/...) run inside the container

NOT WORKING:
- access to etcd inside the container from external hosts; external hosts need access to weave network!

  ```
  weave launch --ipalloc-range 10.250.0.0/24 <PUBLIC_IP_OF_FIRST_HOST>
  ip a a 10.250.0.100/24 dev weave
  ```

SEE ALSO

For configuration of the other components see https://openvstorage.gitbooks.io/openvstorage/content/Installation/geoscalegettingstarted.html

# devstack-template

This will standup a devstack VM 

## Requiremnents

* Host IP of 10.10.0.4 (or override in up.sh)
* 2 network interfaces (internet facing one called `ens224`)

## Execute

```
sudo bash up.sh
```

## What it does

* creates a `stack` user
* all passwords set to `password` 
* eutron networks:
    * private: `10.0.0.0/24`
    * public: `172.18.168.0/24`

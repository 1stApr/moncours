### 0. Description
This module install and configure 
ntpd - network time protocol daemon.
List of ntp servers must be provided in Hiera yaml file.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
Provide timezone and ntp servers list in yaml file

```
  ntp:
    timezone: Europe/Kiev
    servers:
      - 10.64.10.1
      - 10.64.10.2
```    

To view all available timezones use command

```
  $ timedatectl list-timezones
```

And use module by include directive

```
  include ntp
```

To check ntpd status 

```
$ ntpq -pn

     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*10.64.10.1      62.149.0.30      2 u   36   64    1    2.391   -3.232   1.410
 10.64.10.2      .INIT.          16 u    -   64    0    0.000    0.000   0.000
```


### 3. Known backgrounds and issues
not found

### 4. Used documentation


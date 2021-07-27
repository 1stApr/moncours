### 0. Description
This module install OpenSSH server.
And sets ClientAliveInterval option to force SSH server 
send keep alive packets to client and prevent SSH server 
from closing pipe by session inactivity reason.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
Install SSH server

```
    # Install
    include ssh

```


### 3. Known backgrounds and issues
none


### 4. Used documentation
man ssh
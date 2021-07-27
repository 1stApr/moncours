### 0. Description
This module install Apache2 web server.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
Provide ssl certificate information in Hiera yaml

```
apache:
  # certificate parameters
  certificate:
    valid_days: 365
    country_code: UA
    country: Ukraine
    city: Kiev
    organisation: Organisation
```

Then include install class to profile

```
    # Install
    include apache2::install

    # Delete
    include apache2::delete
```


### 3. Known backgrounds and issues
not found yet


### 4. Used documentation


### 0. Description
This module provide puppet functions to deal with Ubuntu apt command.
In this module are functions to:
- create apt repository manually "by hand" by adding repository security key 
  and creating repository file. 
- installing apt repository from deb package.
- remove installed package and run 'autoclean' and 'autoremove' to purge 
  unneeded depencies.

In fist run this module configures apt to always use '--no-install-recommends' and 
'--no-install-suggested' options.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS only.


### 2. Usage
Create repository example:

```
# Key by http link
apt::utils::apt_repository { 'elasticsearch':
  key => 'https://artifacts.elastic.co/GPG-KEY-elasticsearch',
  file => '/etc/apt/sources.list.d/elastic-5.x.list',
  repository => 'deb https://artifacts.elastic.co/packages/5.x/apt stable main',
}

# Key by ID
apt::utils::apt_repository { 'elasticsearch':
  key => 'AA9540512',
  file => '/etc/apt/sources.list.d/elastic-5.x.list',
  repository => 'deb https://artifacts.elastic.co/packages/5.x/apt stable main',
}

```

or without GPG key:

```
apt::utils::apt_repository { 'mongodb':
  file => '/etc/apt/sources.list.d/mongodb-org-3.6.list',
  repository => 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse',
}
```

Unparameterized example:


```
apt::utils::apt_clean { 'clean': }
```


In require parameter. Make attention to first capital letters in defines name:

```
require => Apt::Utils::Apt_repository['elasticsearch'],
```


### 3. Known backgrounds and issues
- There are no manifest for repository removal


### 4. Used documentation

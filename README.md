[![Automated CI testing](https://github.com/openimis/database_ms_sqlserver/actions/workflows/openmis-module-test.yml/badge.svg?branch=develop)](https://github.com/openimis/database_ms_sqlserver/actions/workflows/openmis-module-test.yml)
# openIMIS SQL Server database

This repository contains the openIMIS database for Microsoft SQL Server.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

In order to use and develop the openIMIS database on your local machine, you first need to install:

* Microsoft SQL Server (minimum version 2012)
* Microsoft SQL Server Management Studio (SSMS)

### Installation

To make a copy of this project on your local machine, please follow the next steps:

* clone the repository

```
git clone https://github.com/openimis/database_ms_sqlserver
```

* create a new database (i.e. openIMIS.X.Y.Z where X.Y.Z is the openIMIS database version)

* Execute the initial database creation script (from [Empty databases](./Empty%20databases/) folder) to your SQL Server using SSMS or shell. (The default empty database to create is openIMIS_ONLINE.sql)

### Upgrading

In order to upgrade from the previous version of openIMIS database (see [Versioning](#versioning) section), execute the migration script from [Migration script](./Migration%20script/) folder. We recommend that you create a backup of your openIMIS database before executing the migration script. 

## Deployment

For deployment please read the [installation manual](http://openimis.readthedocs.io/en/latest/web_application_installation.html).

<!--## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.
-->

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/openimis/web_app_vb/tags). 

## Issues

To report a bug, request a new features or asking questions about openIMIS, please use the [openIMIS Service Desk](https://openimis.atlassian.net/servicedesk/customer/portal/1). 

## License

Copyright (c) Swiss Agency for Development and Cooperation (SDC)

This project is licensed under the GNU AGPL v3 License - see the [LICENSE.md](LICENSE.md) file for details.


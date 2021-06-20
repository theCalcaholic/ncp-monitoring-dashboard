# NCP monitoring dashboard

*The quickest way to get a monitoring dashboard for nextcloudpi up and running*

## Prerequisites

* Any current Linux OS (auto-installing docker-compose via the start script is only supported on [Debian](https://debian.org) based systems (e.g. [Ubuntu](https://ubuntu.com)) )
* A (non-docker) ncp server that is reachable from the machine running the dashboard

## Set Up

1. Download and extract or clone this repository to your local computer 
1. Activate the metrics app in your ncp web panel or `ncp-config`
2. [Optional, but recommended] Create a dedicated admin user on your Nextcloud for collecting Nextcloud related metrics. I recommend following this process:
    1. Create a new admin user
    2. Create new device credentials for the user ([as described here](https://docs.nextcloud.com/server/stable/user_manual/en/session_management.html)) and copy the generated password
    3. Uncheck "Allow filesystem access" for the generated device credentials, as will not be needed
3. Configure the variables in .env
    * The URL where your Nextcloud can be reached, goes in `NEXTCLOUD_SERVER`
    * The username and password of an admin user (see 2.) go in `NEXTCLOUD_USERNAME` and `NEXTCLOUD_PASSWORD`
    * The username and password from the ncp metrics app (see 1.) go in `NCP_METRICS_USERNAME` and `NCP_METRICS_PASSWORD`

4. Run the start script from a terminal with the command `./start.sh`

You should now be able to reach your grafana instance at https://localhost:3000 and login with:

user: admin
password: admin

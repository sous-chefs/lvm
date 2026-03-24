# Testing

Please refer to [the community cookbook documentation on testing](https://github.com/chef-cookbooks/community_cookbook_documentation/blob/main/TESTING.MD).

For this cookbook, integration testing currently runs with Vagrant on Ubuntu 22.04 in CI. To mirror CI locally, run Test Kitchen using the default `kitchen.yml` (Vagrant driver), for example:

`kitchen test default-ubuntu-2204 --destroy=always`

Purpose
===
Launch your own github-like private git repository server.

How
===
First, run below command in the sam foler of the docker-compose.yml file. 
> docker-compose up -d

Above commnad will bring up a gitea server cluster which include gitea application server and its back database mysql server. 

You can shutdown the gitea server cluster by docker-compose command
> docker-compose down

The gitea server is listening on port 3000 for http and port 22 for ssh internally, the expose crosponding port is 53000 and 53022 seperately.

For the first time you string up the gitea server cluster, you need initialize your server by setting administrator account through accessing http://localhost:53000. For example:
> * user name: localadmin 
> * password: localadmin@Rdis2fun

With above initialization, you got your settle and can start to use this as your downstream repository server.


Further information
===
Check [../reposync-root/README.md](../reposync-root/README.md) about how to sync your remote repository to your private repository.


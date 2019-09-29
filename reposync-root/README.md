> *Note:*
> > Make sure you have already started your downstream git server before moving forward to below steps. You can refer to [../gitea-root/README](../gitea-root/README.md) to start up a downstream git server quickly.

First, you need build the docker images in your docker host. For example:
> docker build -f Dockerfile.basebuildbox -t kevinwangcy/basebuildbox:latest 

Above is to build the base image for follow image, you just need run above command once in your docker host.

Then, build the docker image which will be used to sync your repositories perodically.
> docker build -t kevinwangcy/reposync:latest .

The 3rd step for preparation is to decide from which repository you want to clone and to which repository you want to upload to. You need refer to [repos/README](repos/README.md) to complete this step. 

Till now you should have already created a folder under *repos* directory with relevant info filled in. Now you can start up a docker container to help you sync your repos from upstream git server to downserver git server peirodically. For example:
> 
> docker run -d --name repo-sync-repo-org-name \
>               -v "$PWD/repos/repo-org-name:/repo" \
>                   kevinwangcy/reposync:latest \
>               -e UPSTREAM_USERNAME='$UPSTREAM_USERNAME' \
>               -e UPSTREAM_PASSWORD='$UPSTREAM_PASSWORD' \
>               -e UPSTREAM_ORGNAME='FOGDB'    \
>               -e DOWNSTREAM_USERNAME='$DOWNSTREAM_USERNAME' \
>               -e DOWNSTREAM_PASSWORD='$DOWNSTREAM_PASSWORD'
>
*Note:* repo-org-name is the folder name you created at above 3rd step.


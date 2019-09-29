First create a folder for your repositories. For example:
> mkdir github-ibalabala

Then copy all file in ../repos-name-org-name into the folder created in above.
> cp -r ../repos-name-org-name ./** ./github-ibalabala

After then you can run the sync-repo.sh to download your repos as local mirror and then put to downstream repo when necessary. For example:
> ./sync-repo.sh 

For detail please check the usage in the script itself.

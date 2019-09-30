First create a folder for your repositories. For example:
> mkdir github-ibalabala

Then copy all file in ../repos-name-org-name into the folder created in above.
> cp -r ../repos-name-org-name ./** ./github-ibalabala

Then you can run below command in the .github-ibalabala to get some tips on how to get ready to start sync your repos.
> ./sync-repo.sh help 

When you got you .env file and ssh ids ready, you're ready to go.

For detail please check the usage in the script itself.

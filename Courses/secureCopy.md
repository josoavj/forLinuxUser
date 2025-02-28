# Using secure copy on Linux

- SCP ou Secure Copy Protocol est un protocole réseau permettant de transférer des fichiers entre des hôtes via une connexion sécurisée. 
- Elle est principalement dédiée aux systèmes Linux et d’autres systèmes compatibles POSIX.


## Options

- Script: `scp [option]`
  - **-r** to copy recursively
  - **-C** to enable compression
  - **-q** to run in a quiet mode
  - **-Q** to disable file transfert statistic
  - **-d** to copy the file if only the destination's folder exist
  - **-u** to delete the source file when the copy is done
  - **-P** to use specific port for the copy


# Secure copy from a remote server to local 

- File: `scp user@ip_remote:/path/to/file /folder/on/you/pc/`
- Folder: `scp -r user@ip_host:/path/to/folder /folder/on/you/pc/`
  

# Secure copy from a remote server to another remote server

- File: `scp user@ip_remote1:/path/to/file user@ip_remote2:/path/to/folder/`
- Folder: `scp -r user@ip_remote1:/path/to/file user@ip_remote2:/path/to/folder/`

# Lumen

**For a live preview of Lumen, feel free to [join the previewers group on lumenapp.com](http://www.lumenapp.com/groups/previewers).**

Lumen started life as a group discussion platform akin to [Google Groups](http://groups.google.com), [GroupServer](http://groupserver.org/), 
[Mailman](http://www.list.org/) or [Sympa](http://www.sympa.org/). Since then, it's gained some powerful extras. An outline of its features:

* Open-source (under [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported](http://creativecommons.org/licenses/by-nc-sa/3.0/))
* Hosted using DigitalOcean/dokku
* Designed for custom domains (group email addresses of the form yourgroup@yourdomain.org)
* Sends and receives mail via regular SMTP and IMAP accounts
* Dual web/email access
* Extensible member profiles
* Flexible digest engine
* Events calendar
* Maps placing people, organisations and venues
* Google Docs integration
* Facebook-style walls

Lumen is written in Ruby using the [Padrino](http://padrinorb.com/) framework. It was originally created for the [New Economy Organisers Network](http://neweconomyorganisersnetwork.org/) (hosted by the [New Economics Foundation](http://neweconomics.org/)) who kindly agreed to open source the project and continue to sponsor its development.

[<img src="http://wordsandwriting.github.io/lumen/images/neon.png">](http://wordsandwriting.github.io/lumen/images/neon.png)

## How the mailing lists work, in brief

1. Your mail server receives a mail to yourgroup@yourdomain.org
2. The mail triggers a simple notification script on the mail server that in turn alerts your web app to the fact there's a new message for the group
3. Your web app connects to the mail server via IMAP to fetch the new mail
4. Your web app distributes the message to group members via SMTP

## Installation instructions for DigitalOcean/dokku

* Create a 2GB (or greater) droplet, which will act as both your web and mail server, with the image 'Dokku 0.6.5 on 14.04' and hostname `$DOMAIN` (this could be a root domain like lumenapp.com, or a subdomain like network.lumenapp.com). SSH into the server via `ssh root@$DOKKU_IP`.

* Run the installation script, replacing `$DOKKU_IP` and `$DOMAIN` with the appropriate values:
  ```
  wget https://raw.github.com/wordsandwriting/lumen/master/script/lumen-install.sh; chmod +x lumen-install.sh; ./lumen-install.sh $DOKKU_IP $DOMAIN
  ```

* Add DNS records (get DKIM key with `nano -$ /etc/opendkim/keys/$MAIL_DOMAIN/mail.txt`):
  ```
  $MAIL_DOMAIN MX $MAIL_SERVER_ADDRESS   
  $MAIL_SERVER_ADDRESS A $DOKKU_IP  
  $MAIL_DOMAIN TXT "v=spf1 mx -all"  
  mail._domainkey.$MAIL_DOMAIN TXT "v=DKIM1; k=rsa; p=..."
  ```

* Visit `$DOMAIN`. (You should be automatically logged in as an administrator. If not, sign in with the email address `admin@example.com` and the password `lumen`.) Change the admin name, email address and password, then click 'Configuration' in the footer to set configuration variables. You're done!

## Switching mail servers

If you switch your mail server, you'll need to re-setup the group mail accounts on the new server. Fire up a console (`padrino c`) and run:
```
Group.each { |group| group.setup_mail_accounts_and_forwarder }
ConversationPost.update_all(imap_uid: nil)
```

# Lumen

**For a live preview of Lumen, feel free to [join the previewers group on lumenapp.com](http://www.lumenapp.com/groups/previewers).**

Lumen started life as a group discussion platform akin to [Google Groups](http://groups.google.com), [GroupServer](http://groupserver.org/), 
[Mailman](http://www.list.org/) or [Sympa](http://www.sympa.org/). Since then, it's gained some powerful extras. An outline of its features:

* Open-source (under [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported](http://creativecommons.org/licenses/by-nc-sa/3.0/))
* Hosted using dokku/Heroku (web app), a VPS (mail sever) and Amazon S3 (file attachments)
* You can run dokku and the mail server on the same VPS
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

In this simple setup, `$DOMAIN = $MAIL_DOMAIN = $MAIL_SERVER_ADDRESS`.

* Create a 2GB (or greater) droplet, which will act as both your web and mail server, with the image 'Dokku 0.6.5 on 14.04' and hostname `$DOMAIN` (this could be a root domain like lumenapp.com, or a subdomain like network.lumenapp.com). SSH into the server via `ssh root@$MAIL_SERVER_IP`

* Install fail2ban: `apt-get install fail2ban`

* Create certificates:

  ```
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/mail.key -out /etc/ssl/certs/mailcert.pem
  ```

  (You can hit enter a bunch of times to leave the fields empty)

* Install mail packages (**make sure you replace `$MAIL_SERVER_ADDRESS` and `$MAIL_DOMAIN` with your domain**). When dovecot-core asks whether you want to create a self-signed SSL certificate, answer no:

  ```
  aptitude install postfix dovecot-core dovecot-imapd opendkim opendkim-tools; mkdir /etc/opendkim; mkdir /etc/opendkim/keys; wget https://raw.github.com/wordsandwriting/lumen/master/script/lumen-install.sh; chmod +x lumen-install.sh; ./lumen-install.sh $MAIL_SERVER_ADDRESS $MAIL_DOMAIN; newaliases; service postfix restart; service dovecot restart; service opendkim restart
  ```

* Visit `$MAIL_SERVER_IP`. Enter `$DOMAIN` as the hostname and check 'Use virtualhost naming for apps'

* Create the dokku app and add the mongo plugin:

  ```
  dokku apps:create $APP_NAME
  dokku plugin:install https://github.com/dokku/dokku-mongo.git mongo
  dokku mongo:create $MONGO_SERVICE_NAME
  dokku mongo:link $MONGO_SERVICE_NAME $APP_NAME
  ```

* Put your private key in `~/.ssh/id_rsa` and `chmod 600 ~/.ssh/id_rsa`. Enable password authentication and set a password for the root user with: `nano /etc/ssh/sshd_config`; uncomment `PasswordAuthentication yes`; `restart ssh`; `passwd`

* Deploy the app via:

  ```
  git clone https://github.com/wordsandwriting/lumen.git; cd lumen; git remote add $APP_NAME dokku@localhost:$APP_NAME; git push $APP_NAME master
  ```

* Set configuration variables (you can get secrets for `$DRAGONFLY_SECRET` and `$SESSION_SECRET` by running `dokku run $APP_NAME rake secret`):
  ```
  dokku config:set $APP_NAME APP_NAME=$APP_NAME DOMAIN=$DOMAIN MAIL_DOMAIN=$MAIL_DOMAIN MAIL_SERVER_ADDRESS=$MAIL_SERVER_ADDRESS MAIL_SERVER_USERNAME=root MAIL_SERVER_PASSWORD=$MAIL_SERVER_PASSWORD S3_BUCKET_NAME=$S3_BUCKET_NAME S3_ACCESS_KEY=$S3_ACCESS_KEY S3_SECRET=$S3_SECRET S3_REGION=$S3_REGION SESSION_SECRET=$SESSION_SECRET DRAGONFLY_SECRET=$DRAGONFLY_SECRET
  ```
  
* Start a worker process: `dokku ps:scale $APP_NAME web=1 worker=1`

* Create default language and database indexes: `dokku run $APP_NAME rake languages:default[English,en]; dokku run $APP_NAME rake mi:create_indexes`

* Set cron tasks with `crontab -e`:

  ```
  0 1 * * * /usr/bin/dokku ps:scale $APP_NAME web=1 worker=1
  0 2 * * * /usr/bin/dokku run $APP_NAME rake groups:check
  0 4 * * * /usr/bin/dokku run $APP_NAME rake cleanup  
  0 8 * * * /usr/bin/dokku run $APP_NAME rake digests:daily  
  0 0 * * 0 /usr/bin/dokku run $APP_NAME rake digests:weekly
  ```

* Add DNS records (get DKIM key with `nano -$ /etc/opendkim/keys/$MAIL_DOMAIN/mail.txt`):

  ```
  $MAIL_DOMAIN MX $MAIL_SERVER_ADDRESS   
  $MAIL_SERVER_ADDRESS A $MAIL_SERVER_IP  
  $MAIL_DOMAIN TXT "v=spf1 mx -all"  
  mail._domainkey.$MAIL_DOMAIN TXT "v=DKIM1; k=rsa; p=..."
  ```

* Visit `$DOMAIN`. (You should be automatically logged in as an administrator. If not, sign in with the email address `admin@example.com` and the password `lumen`.) Change the admin name, email address and password.

* Visit /config and click 'Create notification script'. Add additional configuration variables via `dokku config:set $APP_NAME VAR=$VAR`. You're done!

## Switching mail servers

If you switch your mail server, you'll need to re-setup the group mail accounts on the new server. Fire up a console (`padrino c`) and run:
```
Group.each { |group| group.setup_mail_accounts_and_forwarder }
ConversationPost.update_all(imap_uid: nil)
```

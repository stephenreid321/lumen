DROPLET_IP=$1
APP_NAME=lumen
DOMAIN=$2
MAIL_DOMAIN=$DOMAIN
MAIL_SERVER_ADDRESS=$DOMAIN
MAIL_SERVER_PASSWORD=$(uuidgen)
MONGO_SERVICE_NAME=$APP_NAME

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/mail.key -out /etc/ssl/certs/mailcert.pem -subj "/"
aptitude -y install fail2ban
debconf-set-selections <<< "postfix postfix/mailname string $MAIL_DOMAIN"; debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"; aptitude -y install postfix
DEBIAN_FRONTEND=noninteractive aptitude -y install dovecot-core dovecot-imapd
aptitude -y install opendkim opendkim-tools
mkdir /etc/opendkim; mkdir /etc/opendkim/keys

cat <<EOT >> /etc/postfix/master.cf

submission inet n       -       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_wrappermode=no
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth

EOT

> /etc/postfix/main.cf; cat <<EOT >> /etc/postfix/main.cf

myhostname = $MAIL_SERVER_ADDRESS
myorigin = /etc/mailname
mydestination = $MAIL_SERVER_ADDRESS, localhost, localhost.localdomain
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
smtpd_tls_cert_file=/etc/ssl/certs/mailcert.pem
smtpd_tls_key_file=/etc/ssl/private/mail.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
smtpd_tls_security_level=may
smtpd_tls_protocols = !SSLv2, !SSLv3
local_recipient_maps = proxy:unix:passwd.byname \$alias_maps
milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301
virtual_alias_domains = $MAIL_DOMAIN
virtual_alias_maps = hash:/etc/postfix/virtual
home_mailbox = Maildir/

EOT

> /etc/aliases; cat <<EOT >> /etc/aliases

mailer-daemon: postmaster
postmaster: root
nobody: root
hostmaster: root
usenet: root
news: root
webmaster: root
www: root
ftp: root
abuse: root

EOT

> /etc/dovecot/dovecot.conf; cat <<EOT >> /etc/dovecot/dovecot.conf

disable_plaintext_auth = no
mail_privileged_group = mail
mail_location = maildir:~/Maildir
userdb {
  driver = passwd
}
passdb {
  args = %s
  driver = pam
}
protocols = " imap"
service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0660
    user = postfix
  }
}
ssl=required
ssl_cert = </etc/ssl/certs/mailcert.pem
ssl_key = </etc/ssl/private/mail.key

EOT

cat <<EOT >> /etc/opendkim.conf

AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:12301@localhost

SenderHeaders           Sender,From

EOT

cat <<EOT >> /etc/default/opendkim
SOCKET="inet:12301@localhost"
EOT

cat <<EOT >> /etc/opendkim/TrustedHosts
127.0.0.1
localhost
192.168.0.1/24
$MAIL_DOMAIN
EOT

cat <<EOT >> /etc/opendkim/KeyTable
mail._domainkey.$MAIL_DOMAIN $MAIL_DOMAIN:mail:/etc/opendkim/keys/$MAIL_DOMAIN/mail.private
EOT

cat <<EOT >> /etc/opendkim/SigningTable
*@$MAIL_DOMAIN mail._domainkey.$MAIL_DOMAIN
EOT

cd /etc/opendkim/keys
mkdir $MAIL_DOMAIN
cd $MAIL_DOMAIN
opendkim-genkey -s mail -d $MAIL_DOMAIN
chown opendkim:opendkim mail.private

newaliases
service postfix restart
service dovecot restart
service opendkim restart

dokku apps:create $APP_NAME
dokku plugin:install https://github.com/dokku/dokku-mongo.git mongo
dokku mongo:create $MONGO_SERVICE_NAME
dokku mongo:link $MONGO_SERVICE_NAME $APP_NAME

dokku storage:mount $APP_NAME /var/lib/dokku/data/storage:/storage
chmod a+w /var/lib/dokku/data/storage

DOKKU_SETUP_PAGE=$(curl http://$DROPLET_IP)
SSH_PUBLIC_KEY=$(expr "$DOKKU_SETUP_PAGE" : '.*\(ssh-rsa .*\)</textarea>')
curl -d "keys=$SSH_PUBLIC_KEY&hostname=$DOMAIN&vhost=true" http://$DROPLET_IP/setup

ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
cat ~/.ssh/id_rsa.pub | sshcommand acl-add dokku root
ssh-keyscan localhost >> ~/.ssh/known_hosts
cd ~
git clone https://github.com/wordsandwriting/lumen.git
cd lumen
git remote add $APP_NAME dokku@localhost:$APP_NAME
git push $APP_NAME master

sed -i '/PasswordAuthentication yes/s/^#//g' /etc/ssh/sshd_config
restart ssh
echo -e "$MAIL_SERVER_PASSWORD\n$MAIL_SERVER_PASSWORD\n" | passwd

dokku run $APP_NAME rake languages:default[English,en]
dokku run $APP_NAME rake mi:create_indexes
dokku ps:scale $APP_NAME web=1 worker=1

cat <<EOT >> /var/spool/cron/crontabs/root

0 1 * * * /usr/bin/dokku ps:scale $APP_NAME web=1 worker=1
0 2 * * * /usr/bin/dokku run $APP_NAME rake groups:check
0 4 * * * /usr/bin/dokku run $APP_NAME rake cleanup  
0 8 * * * /usr/bin/dokku run $APP_NAME rake digests:daily  
0 0 * * 0 /usr/bin/dokku run $APP_NAME rake digests:weekly

EOT

SESSION_SECRET=$(uuidgen)
DRAGONFLY_SECRET=$(uuidgen)
dokku config:set $APP_NAME APP_NAME=$APP_NAME DOMAIN=$DOMAIN MAIL_DOMAIN=$MAIL_DOMAIN MAIL_SERVER_ADDRESS=$MAIL_SERVER_ADDRESS MAIL_SERVER_USERNAME=root MAIL_SERVER_PASSWORD=$MAIL_SERVER_PASSWORD SESSION_SECRET=$SESSION_SECRET DRAGONFLY_SECRET=$DRAGONFLY_SECRET
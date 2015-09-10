MAIL_SERVER_ADDRESS=$1
MAIL_DOMAIN=$2

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
mydestination = $MAIL_SERVER_ADDRESS, $MAIL_DOMAIN, localhost, localhost.localdomain
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

cd /etc/opendkim/keys; mkdir $MAIL_DOMAIN; cd $MAIL_DOMAIN; opendkim-genkey -s mail -d $MAIL_DOMAIN; chown opendkim:opendkim mail.private; 

APP_NAME=$1
MAIL_SERVER_PASSWORD=$2

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
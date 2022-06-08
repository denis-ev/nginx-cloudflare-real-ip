#!/bin/bash

CLOUDFLARE_FILE_PATH=${1:-/etc/nginx/cloudflare}

echo "#Cloudflare" > $CLOUDFLARE_FILE_PATH;
echo "" >> $CLOUDFLARE_FILE_PATH;

echo "# - IPv4" >> $CLOUDFLARE_FILE_PATH;
for i in `curl -s -L https://www.cloudflare.com/ips-v4`; do
        echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "# - IPv6" >> $CLOUDFLARE_FILE_PATH;
for i in `curl -s -L https://www.cloudflare.com/ips-v6`; do
        echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_FILE_PATH;

#test configuration and reload nginx
nginx -t && systemctl reload nginx

firewall-cmd --permanent --delete-ipset=cfv4
firewall-cmd --permanent --delete-ipset=cfv6
firewall-cmd --permanent --new-ipset=cfv4 --type=hash:net
firewall-cmd --permanent --new-ipset=cfv6 --type=hash:net --option=family=inet6

for cidr in $(curl https://www.cloudflare.com/ips-v4); do \
    firewall-cmd --permanent --ipset=cfv4 --add-entry=$cidr; \
done

for cidr in $(curl https://www.cloudflare.com/ips-v6); do \
    firewall-cmd --permanent --ipset=cfv6 --add-entry=$cidr; \
done

firewall-cmd --reload

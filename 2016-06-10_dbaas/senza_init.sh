senza --region=eu-central-1 init -t base  -v "team_name=buffalo" \
                    -v "team_region=eu-central-1" \
                    -v "team_gateway_zone=buffalo-dev.zalan.do" \
                    -v "ldap_url=ldaps://corp-ldap.auth.zalando.com:636/ou=people,dc=zalan,dc=do" \
                    -v "hosted_zone=db.zalan.do" \
                    -v "master_dns_name=localized-texts.buffalo-dev.db.zalan.do" \
                    -v "add_replica_loadbalancer=1" buffalo_localized-text.yaml \
                    -v "scalyr_account_key=0HEm5L4qDiKyo6w7VvohW5FuUGqW1EnQiFFFjxrmmvHI-"

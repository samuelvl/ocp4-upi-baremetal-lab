variant: fcos
version: 1.1.0
passwd:
  users:
    - name: maintuser
      uid: 10000
      groups:
        - sudo
      ssh_authorized_keys:
        - '${ssh_pubkey}'
    - name: haproxy
      uid: 9999
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
    - name: quay
      uid: 1001
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
    - name: nfs
      uid: 9997
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
    - name: s3
      uid: 9996
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
    - name: psql
      uid: 26
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
    # Change uid to 1001 when fix https://github.com/coreos/ignition/issues/977
    - name: redis
      uid: 9995
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
storage:
  directories:
    - path: /etc/haproxy
      mode: 0755
      user:
        name: haproxy
      group:
        name: haproxy
    - path: /etc/nfs
      mode: 0755
      user:
        name: nfs
      group:
        name: nfs
    - path: /var/lib/nfs/data
      mode: 0755
      user:
        name: nfsnobody
      group:
        name: nfsnobody
    - path: /var/lib/nfs/data/etcd-backup
      mode: 0755
      user:
        name: nfsnobody
      group:
        name: nfsnobody
    - path: /etc/quay
      mode: 0755
      user:
        name: quay
      group:
        name: quay
    - path: /var/lib/quay
      mode: 0755
      user:
        name: quay
      group:
        name: quay
    - path: /var/lib/quay/extra_ca_certs
      mode: 0755
      user:
        name: quay
      group:
        name: quay
    - path: /etc/s3
      mode: 0755
      user:
        name: s3
      group:
        name: s3
    - path: /var/lib/s3/data
      mode: 0755
      user:
        name: s3
      group:
        name: s3
    - path: /etc/psql
      mode: 0755
      user:
        name: psql
      group:
        name: psql
    - path: /var/lib/psql/data
      mode: 0755
      user:
        name: psql
      group:
        name: psql
    - path: /etc/redis
      mode: 0755
      user:
        name: redis
      group:
        name: redis
    - path: /var/lib/redis/data
      mode: 0755
      user:
        id: 1001 # 
      group:
        id: 1001 # 
  files:
    - path: /etc/hostname
      overwrite: true
      mode: 0644
      user:
        name: root
      group:
        name: root
      contents:
        inline: ${fqdn}
    - path: /root/.docker/config.json
      mode: 0640
      user:
        name: root
      group:
        name: root
      contents:
        inline: |
          ${pull_secret}
    - path: /etc/haproxy/haproxy.cfg
      mode: 0640
      user:
        name: haproxy
      group:
        name: haproxy
      contents:
        inline: |
          global
              log    127.0.0.1 local0 notice
              daemon

          defaults
              mode                      http
              default-server            init-addr last,libc,none
              log                       global
              option                    httplog
              option                    dontlognull
              option  http-server-close
              option  forwardfor        except 127.0.0.0/8
              option  redispatch
              timeout http-request      10s
              timeout queue             1m
              timeout connect           10s
              timeout client            1m
              timeout server            1m
              timeout http-keep-alive   10s
              timeout check             10s
              retries                   3

          resolvers dns
              nameserver dns1  ${haproxy_dns}
              resolve_retries  3
              timeout resolve  1s
              timeout retry    1s
              hold    other    30s
              hold    refused  30s
              hold    nx       30s
              hold    timeout  30s
              hold    valid    10s
              hold    obsolete 30s

          listen stats
              bind *:5555
              stats enable
              stats uri /haproxy?stats

          frontend openshift-api-server
              bind *:6443
              default_backend openshift-apiserver
              mode tcp
              option tcplog

          backend openshift-apiserver
              balance source
              mode tcp
              server bootstrap ${ocp_bootstrap_node}:6443 check resolvers dns
       %{ for master_node in ocp_master_nodes ~}
       server ${master_node} ${master_node}:6443 check resolvers dns
       %{ endfor ~}

          frontend machine-config-server
              bind *:22623
              default_backend machine-config-server
              mode tcp
              option tcplog

          backend machine-config-server
              balance source
              mode tcp
              server bootstrap ${ocp_bootstrap_node}:22623 check resolvers dns
       %{ for master_node in ocp_master_nodes ~}
       server ${master_node} ${master_node}:22623 check resolvers dns
       %{ endfor ~}

          frontend ingress-http
              bind *:80
              default_backend ingress-http
              mode tcp
              option tcplog

          backend ingress-http
              balance source
              mode tcp
       %{ for infra_node in ocp_infra_nodes ~}
       server ${infra_node} ${infra_node}:80 check resolvers dns
       %{ endfor ~}

          frontend ingress-https
              bind *:443
              default_backend ingress-https
              mode tcp
              option tcplog

          backend ingress-https
              balance source
              mode tcp
       %{ for infra_node in ocp_infra_nodes ~}
       server ${infra_node} ${infra_node}:443 check resolvers dns
       %{ endfor ~}

    - path: /etc/nfs/configuration.env
      overwrite: true
      mode: 0640
      user:
        name: nfs
      group:
        name: nfs
      contents:
        inline: |
          NFS_DIR=/nfs-share
          NFS_DOMAIN=*
          NFS_OPTION=fsid=0,rw,sync,insecure,all_squash,anonuid=65534,anongid=65534,no_subtree_check,nohide
    - path: /etc/quay/configuration.env
      overwrite: true
      mode: 0640
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
          DEBUGLOG=false
          IGNORE_VALIDATION=false
    - path: /etc/quay/create-user.sh
      overwrite: true
      mode: 0740
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
            #!/usr/bin/env bash
            username=$${1}
            password=$${2}
            quay_healthz="https://${quay_host}:${quay_port_tls}/health/instance"

            # Wait until the Quay instance is ready
            while [[ "$(curl -ks -o /dev/null -w ''%%{http_code}'' $${quay_healthz})" != "200" ]]; do
                echo "Quay is down, waiting until it is running..."
                sleep 1;
            done

            # Create the user in the public.user table
            psql postgresql://${psql_user}:${psql_pass}@${psql_host}:${psql_port}/${psql_db} \
            -c "INSERT INTO public.user
                    (uuid,
                    username,
                    password_hash,
                    email,
                    verified,
                    organization,
                    robot,
                    invoice_email,
                    last_invalid_login,
                    creation_date)
                SELECT
                    '$(uuidgen)',
                    '$${username}',
                    '$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$${password}', bcrypt.gensalt(rounds=12)).decode())")',
                    '$${username}@admin.io',
                    't',
                    'f',
                    'f',
                    'f',
                    '1990-01-01 00:00:00.000000',
                    '1990-01-01 00:00:00.000000'
                ON CONFLICT DO NOTHING;"
    - path: /etc/quay/delete-user.sh
      overwrite: true
      mode: 0740
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
          #!/usr/bin/env bash
          username=$${1}
          psql postgresql://${psql_user}:${psql_pass}@${psql_host}:${psql_port}/${psql_db} \
              -c "DELETE FROM public.user WHERE username = '$${username}'"
    - path: /var/lib/quay/config.yaml
      overwrite: true
      mode: 0640
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
          ACTION_LOG_ARCHIVE_LOCATION: default
          ACTION_LOG_ARCHIVE_PATH: /var/log/quay
          ACTION_LOG_ROTATION_THRESHOLD: 1w
          ALLOW_PULLS_WITHOUT_STRICT_LOGGING: true
          AUTHENTICATION_TYPE: Database
          AVATAR_KIND: local
          BUILDLOGS_REDIS:
            host: ${redis_host}
            port: ${redis_port}
            password: ${redis_pass}
          USER_EVENTS_REDIS:
            host: ${redis_host}
            port: ${redis_port}
            password: ${redis_pass}
          CONTACT_INFO: [ "https://changeme.io" ]
          DATABASE_SECRET_KEY: 9fac3284-e4a9-483b-bb9f-6501f65f4fd6
          DB_CONNECTION_ARGS:
            autorollback: true
            threadlocals: true
          DB_URI: postgresql://${psql_user}:${psql_pass}@${psql_host}:${psql_port}/${psql_db}
          DEFAULT_TAG_EXPIRATION: 2w
          DISTRIBUTED_STORAGE_CONFIG:
            default:
              - RadosGWStorage
              - hostname: ${s3_host}
                port: ${s3_port}
                bucket_name: ${s3_bucket}
                access_key: ${s3_user}
                secret_key: ${s3_pass}                    
                is_secure: false
                storage_path: /datastorage/registry
          DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
          DISTRIBUTED_STORAGE_PREFERENCE: [ "default" ]
          FEATURE_ACI_CONVERSION: false
          FEATURE_ACTION_LOG_ROTATION: true
          FEATURE_ANONYMOUS_ACCESS: false
          FEATURE_APP_REGISTRY: false
          FEATURE_APP_SPECIFIC_TOKENS: true
          FEATURE_BITBUCKET_BUILD: false
          FEATURE_BLACKLISTED_EMAILS: false
          FEATURE_BUILD_SUPPORT: false
          FEATURE_CHANGE_TAG_EXPIRATION: false
          FEATURE_DIRECT_LOGIN: true
          FEATURE_GENERAL_OCI_SUPPORT: true
          FEATURE_GITHUB_BUILD: false
          FEATURE_GITHUB_LOGIN: false
          FEATURE_GITLAB_BUILD: false
          FEATURE_GOOGLE_LOGIN: false
          FEATURE_HELM_OCI_SUPPORT: true
          FEATURE_INVITE_ONLY_USER_CREATION: false
          FEATURE_MAILING: false
          FEATURE_NONSUPERUSER_TEAM_SYNCING_SETUP: false
          FEATURE_PARTIAL_USER_AUTOCOMPLETE: false
          FEATURE_PROXY_STORAGE: true
          FEATURE_REPO_MIRROR: false
          FEATURE_REQUIRE_ENCRYPTED_BASIC_AUTH: false
          FEATURE_REQUIRE_TEAM_INVITE: true
          FEATURE_RESTRICTED_V1_PUSH: true
          FEATURE_SECURITY_NOTIFICATIONS: false
          FEATURE_SECURITY_SCANNER: false
          FEATURE_SIGNING: false
          FEATURE_STORAGE_REPLICATION: false
          FEATURE_TEAM_SYNCING: false
          FEATURE_USER_CREATION: false
          FEATURE_USER_LAST_ACCESSED: true
          FEATURE_USER_LOG_ACCESS: false
          FEATURE_USER_METADATA: false
          FEATURE_USER_RENAME: false
          FEATURE_USERNAME_CONFIRMATION: true
          FRESH_LOGIN_TIMEOUT: 10m
          GITHUB_LOGIN_CONFIG: {}
          GITHUB_TRIGGER_CONFIG: {}
          GITLAB_TRIGGER_KIND: {}
          GPG2_PRIVATE_KEY_FILENAME: signing-private.gpg
          GPG2_PUBLIC_KEY_FILENAME: signing-public.gpg
          LDAP_ALLOW_INSECURE_FALLBACK: false
          LDAP_EMAIL_ATTR: mail
          LDAP_UID_ATTR: uid
          LDAP_URI: ldap://localhost
          LOG_ARCHIVE_LOCATION: default
          LOGS_MODEL: database
          LOGS_MODEL_CONFIG: {}
          MAIL_DEFAULT_SENDER: support@quay.io
          MAIL_PORT: 587
          MAIL_USE_AUTH: false
          MAIL_USE_TLS: false
          PREFERRED_URL_SCHEME: https
          REGISTRY_TITLE: Laboratory Quay
          REGISTRY_TITLE_SHORT: Quay
          REPO_MIRROR_INTERVAL: 30
          REPO_MIRROR_TLS_VERIFY: true
          SEARCH_MAX_RESULT_PAGE_COUNT: 10
          SEARCH_RESULTS_PER_PAGE: 10
          SECRET_KEY: 2cfce7fd-77a3-44e9-92d2-973588db19da
          SECURITY_SCANNER_INDEXING_INTERVAL: 30
          SECURITY_SCANNER_V4_ENDPOINT: https://clair.ocp.bmlab.int
          SECURITY_SCANNER_V4_PSK: ZWY2MWplYzlhajcy
          SERVER_HOSTNAME: ${quay_host}:${quay_port_tls}
          SETUP_COMPLETE: true
          SUPER_USERS:
            - ${quay_user}
          TAG_EXPIRATION_OPTIONS: [ "0s", "2w" ]
          TEAM_RESYNC_STALE_TIME: 30m
          TESTING: false
          USE_CDN: false
          USER_RECOVERY_TOKEN_LIFETIME: 30m
          USERFILES_LOCATION: default
    - path: /var/lib/quay/ssl.cert
      overwrite: true
      mode: 0644
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
          ${quay_tls_cert}
    - path: /var/lib/quay/ssl.key
      overwrite: true
      mode: 0640
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
          ${quay_tls_key}
    - path: /var/lib/quay/extra_ca_certs/ca-bundle.crt
      overwrite: true
      mode: 0644
      user:
        name: quay
      group:
        name: quay
      contents:
        inline: |
          ${quay_ca_bundle}
    - path: /etc/s3/configuration.env
      overwrite: true
      mode: 0640
      user:
        name: s3
      group:
        name: s3
      contents:
        inline: |
          MINIO_ROOT_USER=${s3_user}
          MINIO_ROOT_PASSWORD=${s3_pass}
    - path: /etc/s3/create-bucket.sh
      overwrite: true
      mode: 0640
      user:
        name: s3
      group:
        name: s3
      contents:
        inline: |
          #!/usr/bin/env bash
          bucket=$${1}
          /usr/bin/mc config host add s3 \
              http://${s3_host}:${s3_port} ${s3_user} ${s3_pass} --api S3v4
          
          # Wait until the S3 server is ready
          while ! /usr/bin/mc stat s3 2> /dev/null; do
              echo "S3 server is down, waiting until it is running..."
              sleep 1;
          done

          # Create new bucket
          /usr/bin/mc mb s3/$${bucket} || true
    - path: /etc/psql/configuration.env
      overwrite: true
      mode: 0640
      user:
        name: psql
      group:
        name: psql
      contents:
        inline: |
          POSTGRESQL_DATABASE=${psql_db}
          POSTGRESQL_USER=${psql_user}
          POSTGRESQL_PASSWORD=${psql_pass}
    - path: /etc/psql/post-start.sh
      overwrite: true
      mode: 0744
      user:
        name: psql
      group:
        name: psql
      contents:
        inline: |
          #!/usr/bin/env bash
          if psql ${psql_db} -c ''; then
              psql -d ${psql_db} -c "ALTER USER ${psql_user} WITH SUPERUSER;"
              psql -d ${psql_db} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
          fi
    - path: /etc/redis/configuration.env
      overwrite: true
      mode: 0640
      user:
        name: redis
      group:
        name: redis
      contents:
        inline: |
          REDIS_PASSWORD=${redis_pass}
systemd:
  units:
    - name: haproxy.service
      enabled: true
      contents: |
        [Unit]
        Description=HAProxy
        Documentation=https://www.haproxy.org/
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${haproxy_image}
        ExecStart=/bin/podman run --name %N --rm \
            --publish 80:80 \
            --publish 443:443 \
            --publish 6443:6443 \
            --publish 5555:5555 \
            --publish 22623:22623 \
            --volume  /etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro,z \
                ${haproxy_image}
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %N
        ExecReload=/bin/podman restart %N

        [Install]
        WantedBy=multi-user.target
    - name: nfs.service
      enabled: true
      contents: |
        [Unit]
        Description=NFS Server
        Documentation=https://linux-nfs.org/wiki/index.php/Main_Page
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${nfs_image}
        ExecStart=/bin/podman run --name %N --rm \
            --privileged \
            --publish  2049:2049 \
            --env-file /etc/nfs/configuration.env \
            --volume   /var/lib/nfs/data:/nfs-share:z \
                ${nfs_image}
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %N
        ExecReload=/bin/podman restart %N

        [Install]
        WantedBy=multi-user.target
    - name: quay.service
      enabled: true
      contents: |
        [Unit]
        Description=Red Hat Quay
        Documentation=https://access.redhat.com/documentation/en-us/red_hat_quay
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${quay_image}
        ExecStart=/bin/podman run --name %N --rm \
            --privileged \
            --sysctl   net.core.somaxconn=4096 \
            --publish  ${quay_port}:8080 \
            --publish  ${quay_port_tls}:8443 \
            --env-file /etc/quay/configuration.env \
            --volume   /var/lib/quay:/conf/stack:z \
                ${quay_image}
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %N
        ExecReload=/bin/podman restart %N

        [Install]
        WantedBy=multi-user.target
    - name: quay-users.service
      enabled: true
      contents: |
        [Unit]
        Description=Create Red Hat Quay Superuser 
        After=quay.service
        Requires=quay.service

        [Service]
        Type=oneshot
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${quay_image}
        ExecStart=/bin/podman run --name %N --rm \
            --entrypoint /bin/bash \
            --volume     /etc/quay/create-user.sh:/quay-registry/create-user.sh:z \
            --volume     /etc/quay/delete-user.sh:/quay-registry/src/delete-user.sh:z \
                ${quay_image} \
                    /quay-registry/create-user.sh ${quay_user} ${quay_pass}
        ExecStop=-/bin/podman rm -f %N

        [Install]
        WantedBy=multi-user.target
    - name: s3.service
      enabled: true
      contents: |
        [Unit]
        Description=Minio: Object Storage for the era of the hybrid cloud
        Documentation=https://docs.min.io
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${s3_image}
        ExecStart=/bin/podman run --name %N --rm \
            --publish  ${s3_port}:9000 \
            --env-file /etc/s3/configuration.env \
            --volume   /var/lib/s3/data:/data:z \
                ${s3_image} server /data
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %N
        ExecReload=/bin/podman restart %N

        [Install]
        WantedBy=multi-user.target
    - name: s3-buckets.service
      enabled: true
      contents: |
        [Unit]
        Description=Create Minio S3 buckets 
        After=s3.service
        Requires=s3.service

        [Service]
        Type=oneshot
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${s3_client_image}
        ExecStart=/bin/podman run --name %N --rm \
            --entrypoint /bin/bash \
            --volume     /etc/s3/create-bucket.sh:/opt/create-bucket.sh:z \
                ${s3_client_image} \
                    /opt/create-bucket.sh ${s3_bucket}
        ExecStop=-/bin/podman rm -f %N

        [Install]
        WantedBy=multi-user.target
    - name: psql.service
      enabled: true
      contents: |
        [Unit]
        Description=PostgreSQL: The World's Most Advanced Open Source Relational Database
        Documentation=https://www.postgresql.org/
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${psql_image}
        ExecStart=/bin/podman run --name %N --rm \
            --publish  ${psql_port}:5432 \
            --env-file /etc/psql/configuration.env \
            --volume   /etc/psql/post-start.sh:/opt/app-root/src/postgresql-start/post-start.sh:z \
            --volume   /var/lib/psql/data:/var/lib/pgsql/data:z \
                ${psql_image}
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %N
        ExecReload=/bin/podman restart %N

        [Install]
        WantedBy=multi-user.target
    - name: redis.service
      enabled: true
      contents: |
        [Unit]
        Description=Redis 5 Container
        Documentation=https://github.com/sclorg/redis-container
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull ${redis_image}
        ExecStart=/bin/podman run --name %N --rm \
            --publish  ${redis_port}:6379 \
            --env-file /etc/redis/configuration.env \
            --volume   /var/lib/redis/data:/var/lib/redis/data:z \
                ${redis_image}
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %N
        ExecReload=/bin/podman restart %N

        [Install]
        WantedBy=multi-user.target

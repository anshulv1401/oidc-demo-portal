FROM nginx as build

RUN apt-get -y update;
RUN apt install -y curl

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - 
RUN apt-get install -y nodejs


ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_group=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_uid=1001

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_gid=1001

ARG idp_api_url
ARG idp_aud_url
ARG private_key
ARG idp_ui_base_url
ARG oidc_base_url
ARG redirect_uri
ARG client_id
ARG acrs


ENV PORT=8888
ENV IDP_BASE_URL=${idp_api_url}
ENV IDP_AUD_URL=${idp_aud_url}
ENV PRIVATE_KEY=${private_key}
ENV IDP_UI_BASE_URL=$idp_ui_base_url
ENV OIDC_BASE_URL=$oidc_base_url
ENV REDIRECT_URI=$redirect_uri
ENV CLIENT_ID=$client_id
ENV ACRS=$acrs


# RUN addgroup -g ${container_user_gid} ${container_user} && \
#     adduser ${container_user} -G ${container_user} -u ${container_user_uid} --disabled-password

## oidc-ui
WORKDIR ./app/oidc-ui
COPY ./oidc-ui ./
RUN npm install
RUN npm run build

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/oidc-ui/build /usr/share/nginx/html

RUN apt-get -y update \
    && apt-get install -y wget unzip zip \
    && groupadd -g ${container_user_gid} ${container_user_group} \
    && useradd -u ${container_user_uid} -g ${container_user_group} -s /bin/sh -m ${container_user} \
    && mkdir -p /var/run/nginx /var/tmp/nginx ${work_dir}/locales\
    && chown -R ${container_user}:${container_user} /usr/share/nginx /var/run/nginx /var/tmp/nginx ${work_dir}/locales

## oidc server
WORKDIR ./app/oidc-server
COPY ./oidc-server ./
RUN npm install

# change permissions of file inside working dir
# RUN chown -R ${container_user}:${container_user} ${work_dir}

# select container user for all tasks
# USER ${container_user}

EXPOSE ${PORT}
EXPOSE 5000

CMD ["node", "./app.js"]
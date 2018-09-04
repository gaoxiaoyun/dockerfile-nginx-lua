FROM alpine:3.8

MAINTAINER Kronuz
 
ENV NGINX_VERSION 1.14.0
# 代理,用于文件下载
ENV HTTP_PROXY 'http://10.179.161.248:3128'
ENV HTTPS_PROXY 'http://10.179.161.248:3128'
ENV BUILD_ROOT /usr/src
# nginx运行lua需要
ADD nginx_devel_kit.tar.gz  $BUILD_ROOT/
ADD nginx_lua_module.tar.gz  $BUILD_ROOT/
# lua中运行cjson需要，包中的Makfile文件需要手工修改LUA_INCLUDE_DIR路径为luajit的安装路径：/usr/local/include/luajit-2.0
ADD lua-cjson-2.1.0.tar.gz $BUILD_ROOT/
# lua中运行kafka需要
ADD lua-resty-kafka-0.06.tar.gz $BUILD_ROOT/
# lua中运行uuid需要
ADD lua-resty-jit-uuid-0.0.7.tar.gz $BUILD_ROOT/
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
  && export http_proxy=http://10.179.161.248:3128 \
  && export https_proxy=http://10.179.161.248:3128 \
  && export no_proxy=".huawei.com,<local>,127.0.0.1" \
  && CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-pcre \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module \
    --add-module=/usr/src/ngx_devel_kit-0.3.0 \
    --add-module=/usr/src/lua-nginx-module-0.10.13 \
  " \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  && apk add libgcc \
  && apk add --no-cache --virtual .build-deps \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev \
  && mkdir -p $BUILD_ROOT \
  && cd $BUILD_ROOT \
  #  安装nginx需要
  && curl -k https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
  && curl -k https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
  #   && curl -k https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz -o headers-more-nginx-module.tar.gz \
  #   && curl -k http://h264.code-shop.com/download/nginx_mod_h264_streaming-2.2.7.tar.gz -o nginx_mod_h264_streaming.tar.gz \
  #   && curl -k https://github.com/wandenberg/nginx-push-stream-module/archive/0.5.4.tar.gz -o nginx-push-stream-module.tar.gz \
  #  nginx运行lua需要luajit,nginx_devel_kit,nginx_lua_module
  && curl -k http://luajit.org/download/LuaJIT-2.0.5.tar.gz -o LuaJIT-2.0.5.tar.gz \
  # curl 内网下载不下来，用ADD直接传入
  # && curl -k http://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz -o nginx_devel_kit.tar.gz \
  # && curl -k http://github.com/openresty/lua-nginx-module/archive/v0.10.13.tar.gz -o nginx_lua_module.tar.gz \
  # && export GNUPGHOME="$(mktemp -d)" \
  # && rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
  # && mkdir -p /usr/src \
  # tar -zxC参数不可识别,改成vxzf了
  # 安装nginx和LuaJIT
  && tar vxzf  nginx.tar.gz \
  #   && tar vxzf /usr/src -f headers-more-nginx-module.tar.gz \
  #   && tar vxzf /usr/src -f nginx_mod_h264_streaming.tar.gz \
  #   && tar vxzf /usr/src -f nginx-push-stream-module.tar.gz \
  && echo "tar files LuaJIT..." \
  && tar vxzf LuaJIT-2.0.5.tar.gz \
  #   && tar vxzf nginx_devel_kit.tar.gz \
  #   && tar vxzf nginx_lua_module.tar.gz \
  && echo "rm tar files above..." \
  && rm *.tar.gz \
  && cd $BUILD_ROOT/LuaJIT-2.0.5 \
  && make install \
  && cd $BUILD_ROOT/nginx-$NGINX_VERSION \
  && ./configure $CONFIG --with-debug \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && mv objs/nginx objs/nginx-debug \
  && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
  && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
  && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
  && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
  && ./configure $CONFIG \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && mkdir -p /usr/share/nginx/html/ \
  && install -m644 html/index.html /usr/share/nginx/html/ \
  && install -m644 html/50x.html /usr/share/nginx/html/ \
  && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
  && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
  && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
  && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
  && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
  && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx* \
  && strip /usr/lib/nginx/modules/*.so \
  # 安装cjson
  && echo "make cjson" \  
  && cd $BUILD_ROOT/lua-cjson-2.1.0 \
  && make \
  && make install \
  # 安装lua-kafka
  && cp -rf $BUILD_ROOT/lua-resty-kafka-0.06/lib/resty  /usr/local/share/lua/5.1/ \
  # 安装jit-uuid
  && cp -rf $BUILD_ROOT/lua-resty-jit-uuid-0.0.7/lib/resty  /usr/local/share/lua/5.1/ \
  && rm -rf $BUILD_ROOT/nginx-$NGINX_VERSION \
  #   && rm -rf $BUILD_ROOT/headers-more-nginx-module-0.33 \
  #   && rm -rf $BUILD_ROOT/nginx-push-stream-module-0.5.4 \
  #   && rm -rf $BUILD_ROOT/nginx_mod_h264_streaming-2.2.7 \
  \
  # Bring in gettext so we can get `envsubst`, then throw
  # the rest away. To do this, we need to install `gettext`
  # then move `envsubst` out of the way so `gettext` can
  # be deleted completely, then move `envsubst` back.
  && apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
  \
  && runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && apk del .build-deps \
  && apk del .gettext \
  && mv /tmp/envsubst /usr/local/bin/ \
  \
  # Bring in tzdata so users could set the timezones through the environment
  # variables
  && apk add --no-cache tzdata \
  \
  # forward request and error logs to docker log collector
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log 

    
  # COPY nginx.conf /etc/nginx/nginx.conf
  # COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]

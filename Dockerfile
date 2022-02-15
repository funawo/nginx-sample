FROM centos:7.9.2009

#USER root

# dependency packages preinstall
RUN yum install -y pcre-devel zlib-devel gcc make git patch httpd-tools

# work directory
RUN mkdir -p /path/to
WORKDIR /path/to

# nginx v1.18.0 download
RUN curl -sO http://nginx.org/download/nginx-1.18.0.tar.gz
RUN tar -xvzf nginx-1.18.0.tar.gz && rm -f nginx-1.18.0.tar.gz

# nginx connect module download
RUN git clone https://github.com/chobits/ngx_http_proxy_connect_module -b v0.0.2

# Lua download & build
RUN curl -sO http://luajit.org/download/LuaJIT-2.0.5.tar.gz
RUN tar zxvf LuaJIT-2.0.5.tar.gz && rm -f LuaJIT-2.0.5.tar.gz
WORKDIR LuaJIT-2.0.5
RUN make install PREFIX=/path/to/luajit

# nginx develop kit
WORKDIR ..
RUN curl -sL https://github.com/simpl/ngx_devel_kit/archive/v0.3.1.tar.gz -o ngx_devel_kit-v0.3.1.tar.gz 
RUN tar xzvf ngx_devel_kit-v0.3.1.tar.gz && rm -f xzvf ngx_devel_kit-v0.3.1.tar.gz

# lua nginx module
RUN curl -sL https://github.com/openresty/lua-nginx-module/archive/v0.10.20.tar.gz -o ngx_lua-v0.10.20.tar.gz
RUN tar xzvf ngx_lua-v0.10.20.tar.gz && rm -f xzvf ngx_lua-v0.10.20.tar.gz

# lua core
RUN curl -sL https://github.com/openresty/lua-resty-core/archive/v0.1.22.tar.gz  -o lua-core-v0.1.22.tar.gz
RUN tar xzvf lua-core-v0.1.22.tar.gz && rm -f lua-core-v0.1.22.tar.gz
RUN mkdir -p /usr/local/share/lua/5.1/resty
RUN ln -s /path/to/lua-resty-core-0.1.22/lib/resty/core /usr/local/share/lua/5.1/resty/core
RUN ln -s /path/to/lua-resty-core-0.1.22/lib/resty/core.lua /usr/local/share/lua/5.1/resty/core.lua

# lua lrucach
RUN curl -sL https://github.com/openresty/lua-resty-lrucache/archive/v0.11.tar.gz -o lrucach-v0.11.tar.gz
RUN tar xzvf lrucach-v0.11.tar.gz && rm -f lrucach-v0.11.tar.gz
RUN ln -s /path/to/lua-resty-lrucache-0.11/lib/resty/lrucache /usr/local/share/lua/5.1/resty/lrucache
RUN ln -s /path/to/lua-resty-lrucache-0.11/lib/resty/lrucache.lua /usr/local/share/lua/5.1/resty/lrucache.lua

# lua lrucache
#RUN curl -sL https://github.com/openresty/luajit2/archive/v2.1-20220111.tar.gz  -o luajit-v2.1.tar.gz
#RUN tar xzvf luajit-v2.1.tar.gz && rm -f luajit-v2.1.tar.gz
#WORKDIR /path/to/luajit2-2.1-20220111
#RUN make && make install PREFIX=/path/to
#
RUN find  /path/to/luajit -name *.lua

# lua build env
ENV LUAJIT_LIB=/path/to/luajit/lib
ENV LUAJIT_INC=/path/to/luajit/include/luajit-2.0

WORKDIR /path/to/nginx-1.18.0
RUN patch -p1 < /path/to/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1018.patch
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --modules-path=/usr/lib64/nginx/modules \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    #--user=nginx \
    #--group=nginx \
    --add-module=/path/to/ngx_http_proxy_connect_module \
    --with-ld-opt="-Wl,-rpath,/path/to/luajit/lib" \
    --add-module=/path/to/ngx_devel_kit-0.3.1 \
    --add-module=/path/to/lua-nginx-module-0.10.20
RUN make && make install
RUN mkdir /etc/nginx/conf.d
#RUN useradd -r nginx
#USER nginx


EXPOSE 80/tcp
COPY docker-entrypoint.sh /tmp
#CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
COPY proxy_auth.lua /etc/nginx
RUN chmod +x /tmp/docker-entrypoint.sh
RUN htpasswd -bc /etc/nginx/pwd hello world
CMD ["/tmp/docker-entrypoint.sh"]
#ENTRYPOINT /usr/sbin/nginx -g "daemon off;"



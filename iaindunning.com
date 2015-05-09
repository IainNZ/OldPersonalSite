server {
  # Listen for IPv4 on the default HTTP port 80
  listen 80;

  # The root directory of the site
  root /var/www/iaindunning.com/public_html;

  # Let nginx know what the default url is
  index index.html;

  # The domain name of our website
  server_name iaindunning.com;

  # Error page
  error_page 404 /404.html;

  # Redirect old posts
  rewrite ^/2014/(.*)$ /blog/$1 permanent;
  rewrite ^/2014/(.*)$ /blog/$1 permanent;
  rewrite ^/2012/(.*)$ /blog/$1 permanent;
}

server {
  # Redirect www.iaindunning.com/* to iaindunning.com/*
  listen 80;
  server_name www.iaindunning.com;
  return 301 http://iaindunning.com$request_uri;
}

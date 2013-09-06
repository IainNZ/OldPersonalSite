server {
  # Listen for IPv4 on the default HTTP port 80
  listen 80;

  # The root directory of th esite
  root /var/www/iaindunning.com/public_html;

  # Let nginx know what the default url is
  index index.html;

  # The domain name of our website
  server_name iaindunning.com;

  # Redirects from old blog
  rewrite ^/oldpost\.html$ /index.html permanent;
  rewrite ^/2012/comparing-the-weather-of-different-cities-part-1/$ /2013/comparing-the-weather-of-different-cities.html.permanent;
  rewrite ^/2013/comparing-the-weather-of-different-cities-part-2/$ /2013/comparing-the-weather-of-different-cities.html permanent;
  rewrite ^/2012/solving-quadratic-knapsack-problems-with-gurobi-5/$ /index/html permanent;
  
}

server {
  # Redirect www.iaindunning.com/* to iaindunning.com/*
  listen 80;
  server_name www.iaindunning.com;
  return 301 http://iaindunning.com$request_uri;
}

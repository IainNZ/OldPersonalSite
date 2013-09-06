server {
  # Listen for IPv4 on the default HTTP port 80
  listen 80;

  # The root directory of th esite
  root /var/www/iaindunning.com/public_html;

  # Let nginx know what the default url is
  index index.html;

  # The domain name of our website
  server_name iaindunning.com;

  # Redirect old posts
  rewrite ^/2012/installing-julia-on-linux-mint-13/$ /index.html permanent;
  rewrite ^/2012/solving-quadratic-knapsack-problems-with-gurobi-5/$ /index.html permanent;
  rewrite ^/2012/comparing-the-weather-of-different-cities-part-1/$ /2013/comparing-the-weather-of-different-cities.html permanent;
  rewrite ^/2012/implementing-second-order-cone-constraints-in-gurobi/$ /2012/implementing-second-order-cone-constraints-in-gurobi.html permanent;
  rewrite ^/2013/comparing-the-weather-of-different-cities-part-2/$ /2013/comparing-the-weather-of-different-cities.html permanent;
  rewrite ^/2013/mit-iap-2013/$ /2013/mit-iap-2013.html permanent;
  rewrite ^/2013/experiences-with-xmonad-and-ubuntu-12/$ /2013/experiences-with-xmonad-and-ubuntu-12.html permanent;
  rewrite ^/2013/simulation-study-of-a-laundry-room/$ /2013/simulation-study-of-a-laundry-room.html permanent;
  rewrite ^/2013/an-icelandic-adventure/$ /2013/an-icelandic-adventure.html permanent;
}

server {
  # Redirect www.iaindunning.com/* to iaindunning.com/*
  listen 80;
  server_name www.iaindunning.com;
  return 301 http://iaindunning.com$request_uri;
}

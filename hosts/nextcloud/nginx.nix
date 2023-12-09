{ config, ... }:

let
  domain = "chrysalis.fun";
  subdomain = "wordpress." + domain;
in
{
  services.wordpress = {
    webserver = "nginx";
    sites.${subdomain} = {
      settings = {
        WPLANG = "en_US";
      };
    };
  };

  security.acme.certs.${domain} = {
    webroot = "/var/lib/acme/${domain}";
    extraDomainNames = [
      subdomain
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    globalRedirect = subdomain;
    useACMEHost = domain;
    acmeRoot = config.security.acme.certs.${domain}.webroot;
  };

  services.nginx.virtualHosts.${subdomain} = {
    forceSSL = true;
    useACMEHost = domain;
    acmeRoot = config.security.acme.certs.${domain}.webroot;
  };
}
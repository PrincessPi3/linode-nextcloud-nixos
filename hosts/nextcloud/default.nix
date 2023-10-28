{
  config,
  pkgs,
  lib,
  ...
}: {
  time.timeZone = "America/Denver";
  # security.acme.acceptTerms = true;
  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };
virtualisation.oci-containers.backend = "docker";
nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
  ];
#  age.secrets.secret1 = {
    #file = ../../secrets/nextcloudPassword;
    # path = "/var/lib/secrets/nextcloudpass";
    #mode = "770";
    #owner = "nextcloud";
#  };
  security.pam = {
    enableSSHAgentAuth = true;
    services.sudo.sshAgentAuth = true;
  };
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    startWhenNeeded = true;
    # kexAlgorithms = [ "curve25519-sha256@libssh.org" ];
  };
  services.nginx = {
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };
  # Forwards the Host header which is required for Nextcloud

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
    locations = {"/".proxyPass = "https://${config.services.nextcloud.hostName}";};
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "human.bagel@gmail.com";
  };
  users.users = {
    sky = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVQk2zAil8R7uNuyer1o0+IP//nP7+vLPaUjTkmbYth"      ];
      extraGroups = ["wheel"];
    };
  };
  services.tailscale.enable = true;
  services.nextcloud = {
    enable = true;
    hostName = "chrysalis.fun";
    package = pkgs.nextcloud27;
    enableBrokenCiphersForSSE = false;
    https = true;
    configureRedis = true;
    phpOptions = {
      upload_max_filesize = lib.mkForce "16G";
      post_max_size = lib.mkForce "16G";
    };
    config = {
      adminpassFile = "${pkgs.writeText "nextcloud-admin-pass" "CHANGEMEINSECUREASAP"}";
    };
  };

  services.kasmweb = {
    enable = true;
    listenPort = 5899;
    #services.kasmweb.networkSubnet = ""172.1.0.0/16""
    #listenAddress = "127.0.0.1";
    #defaultUserPassword = "CHANGEMEINSECURE";
    #defaultAdminPassword = "CHANGEMEINSECURE"; 
  };

services.nginx.virtualHosts."kasm.chrysalis.fun" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
        proxyPass = "http://127.0.0.1:5899";
        proxyWebsockets = true;
    };
};
  networking.firewall.allowedTCPPorts = [22 80 443];
  system.stateVersion = "23.05";
  system.autoUpgrade = {
    dates = "daily";
    enable = true;
    allowReboot = false;
    randomizedDelaySec = "60min";
    flake = "github:PrincessPi3/linode-nextcloud-nixos";
  };
  networking.hostName = "nextcloud";
}

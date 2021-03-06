{ config, pkgs, lib, ... }:
let
  meta = import ./meta.nix;
  machine-config = lib.getAttr meta.name {
    Larry = [
      {
        imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];
      
        boot.initrd.availableKernelModules = [ "ahci" "xhci_hcd" ];
        boot.initrd.kernelModules = [ "wl" ];
      
        boot.kernelModules = [ "kvm-intel" "wl" ];
        boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
      }
      {
        fileSystems = {
          "/" = {
            device = "/dev/disk/by-uuid/ba82dd25-a9e5-436f-ae76-4ee44d53b2c6";
            fsType = "ext4";
          };
          "/home" = {
            device = "/dev/disk/by-uuid/b27c07d0-aaf7-44a1-87e1-5a2cb30954ec";
            fsType = "ext4";
          };
        };
      }
      {
        swapDevices = [
          # TODO: set priority
          # { device = "/dev/disk/by-uuid/f0bd0438-3324-4295-9981-07015fa0af5e"; }
          { device = "/dev/disk/by-uuid/75822d9d-c5f0-495f-b089-f57d0de5246d"; }
        ];
      }
      {
        boot.loader.grub = {
          enable = true;
          version = 2;
          device = "/dev/sda";
          extraEntries = ''
            menuentry 'Gentoo' {
              configfile (hd1,1)/grub2/grub.cfg
            }
          '';
        };
      }
      {
        nix.maxJobs = 8;
        nix.buildCores = 8;
      
        networking = {
          hostName = "Larry";
      
          useDHCP = false;
          wicd.enable = true;
          wireless.enable = false;
        };
      
        services.xserver.synaptics = {
          enable = true;
          twoFingerScroll = true;
          vertEdgeScroll = true;
        };
      }
      {
        hardware.nvidiaOptimus.disable = true;
      }
      {
        services.logstash = {
          enable = true;
          inputConfig = ''
            file {
              path => "/home/rasen/log.txt.processed"
              sincedb_path => "/home/rasen/.log.txt.sincedb"
              codec => "json"
              start_position => "beginning"
              tags => [ "awesomewm" ]
              type => "awesomewm"
            }
            file {
              path => "/home/rasen/log.txt.ashmalko"
              sincedb_path => "/home/rasen/.log.txt.ashmalko.sincedb"
              codec => "json"
              start_position => "beginning"
              tags => [ "awesomewm" ]
              type => "awesomewm"
            }
          '';
          filterConfig = ''
            if [path] == "/home/rasen/log.txt.ashmalko" {
              mutate {
                replace => [ "host", "ashmalko" ]
              }
            }
          '';
          outputConfig = ''
            elasticsearch {
              index => "quantified-self"
              document_type => "awesomewm"
            }
          '';
        };
      
        services.elasticsearch = {
          enable = true;
          cluster_name = "ashmalko";
          extraConf = ''
            node.name: "${meta.name}"
          '';
        };
      
        services.kibana = {
          enable = true;
        };
      }
      {
        networking.localCommands = ''
          ip route del 10.2.0.0/22 via 10.7.0.52 2> /dev/null || true
          ip route add 10.2.0.0/22 via 10.7.0.52
        '';
      }
    ];
    ashmalko = [
      {
        networking.hostName = "ashmalko";
      
        nix.maxJobs = 4;
        nix.buildCores = 4;
      }
      {
        imports = [
          <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
        ];
      
        boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];
      
        boot.kernelParams = [ "intel_pstate=no_hwp" ];
        boot.loader.grub = {
          enable = true;
          version = 2;
          device = "/dev/sda";
          efiSupport = true;
        };
        boot.loader.efi.canTouchEfiVariables = true;
      }
      {
        boot.initrd.luks.devices = [
          {
            name = "root";
            device = "/dev/disk/by-uuid/a3eb801b-7771-4112-bb8d-42a9676e65de";
            preLVM = true;
            allowDiscards = true;
          }
        ];
      
        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/4184-7556";
          fsType = "vfat";
        };
      
        fileSystems."/" = {
          device = "/dev/disk/by-uuid/84d89f4b-7707-4580-8dbc-ec7e15e43b52";
          fsType = "ext4";
          options = [ "noatime" "nodiratime" "discard" ];
        };
      
        swapDevices = [
          { device = "/dev/disk/by-uuid/5a8086b0-627e-4775-ac07-b827ced6998b"; }
        ];
      }
      {
        hardware.pulseaudio = {
          enable = true;
          support32Bit = true;
        };
        environment.systemPackages = [ pkgs.pavucontrol ];
      }
      {
        services.gitolite = {
          enable = true;
          user = "git";
          adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJhMhxIwZJgIY6CNSNEH+BetF/WCUtDFY2KTIl8LcvXNHZTh4ZMc5shTOS/ROT4aH8Awbm0NjMdW33J5tFMN8T7q89YZS8hbBjLEh8J04Y+kndjnllDXU6NnIr/AenMPIZxJZtSvWYx+f3oO6thvkZYcyzxvA5Vi6V1cGx6ni0Kizq/WV/mE/P1nNbwuN3C4lCtiBC9duvoNhp65PctQNohnKQs0vpQcqVlfqBsjQ7hhj2Fjg+Ofmt5NkL+NhKQNqfkYN5QyIAulucjmFAieKR4qQBABopl2F6f8D9IjY8yH46OCrgss4WTf+wxW4EBw/QEfNoKWkgVoZtxXP5pqAz rasen@Larry";
        };
      }
      {
        services.avahi.interfaces = [ "enp0s31f6" ];
      }
      {
        networking.firewall.allowedTCPPorts = [
          1883 8883 # Zink
          3000      # Grafana
        ];
      
        systemd.services.zink = {
          description = "Zink service";
          wantedBy = [ "multi-user.target" ];
          after = [ "grafana.service" ];
      
          serviceConfig =
            let zink =
              pkgs.rustPlatform.buildRustPackage {
                name = "zink-0.0.1";
      
                src = pkgs.fetchFromGitHub {
                  owner = "rasendubi";
                  repo = "zink";
                  rev = "influxdb-0.0.1";
                  sha256 = "1sw07p2a83s34mp69snz1znwqp8xlba8dqc5y6iqfhyc3zwwbd3w";
                };
      
                depsSha256 = "1dvk5l32nrpxy7h5pfiqssx06xd72pszd8kr2f2y3ba288ck97rr";
              };
            in {
              ExecStart = "${zink}/bin/zink timestamp,tagId,batteryLevel,temperature";
              Restart = "on-failure";
            };
        };
      
        services.influxdb.enable = true;
      
        services.grafana = {
          enable = true;
          addr = "0.0.0.0";
          port = 3000;
      
          domain = "ashmalko.local";
          auth.anonymous.enable = true;
        };
      }
      {
        networking.nat = {
          enable = true;
          internalInterfaces = [ "tap0" ];
          externalInterface = "enp0s31f6";
        };
      }
    ];
  };

in
{
  imports = [
    {
      nixpkgs.config.allowUnfree = true;

      # The NixOS release to be compatible with for stateful data such as databases.
      system.stateVersion = "15.09";
    }

    {
      nix.nixPath =
        let dotfiles = "/home/rasen/dotfiles";
        in [
          "nixos-config=${dotfiles}/nixos/configuration.nix"
          "dotfiles=${dotfiles}"
          "${dotfiles}/channels"
        ];
    }
    {
      system.copySystemConfiguration = true;
    }
    {
      users.extraUsers.rasen = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "users" "wheel" "input" ];
        initialPassword = "HelloWorld";
      };
    }
    {
      nix.useSandbox = "relaxed";
    }
    {
      services.locate = {
        enable = true;
        localuser = "rasen";
      };
    }
    {
      services.openvpn.servers = {
        kaa.config = ''
          client
          dev tap
          port 22
          proto tcp
          tls-client
          persist-key
          persist-tun
          ns-cert-type server
          remote vpn.kaa.org.ua
          ca /root/.vpn/ca.crt
          key /root/.vpn/alexey.shmalko.key
          cert /root/.vpn/alexey.shmalko.crt
        '';
      };
    }
    {
      services.avahi = {
        enable = true;
        browseDomains = [ ];
        interfaces = [ "tap0" ];
        nssmdns = true;
        publish = {
          enable = true;
          addresses = true;
        };
      };
    }
    {
      systemd.services.avahi-daemon.wantedBy = [ "multi-user.target" ];
      systemd.services.avahi-daemon.after = [ "openvpn-kaa.target" ];
    }
    {
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
    
        # Disable default firewall rules
        ports = [];
        listenAddresses = [
          { addr = "0.0.0.0"; port = 22; }
        ];
      };
    
      # allow ssh from VPN network only
      networking.firewall = {
        extraCommands = ''
          ip46tables -D INPUT -i tap0 -p tcp -m tcp --dport 22 -j ACCEPT 2> /dev/null || true
          ip46tables -A INPUT -i tap0 -p tcp -m tcp --dport 22 -j ACCEPT
        '';
      };
    }
    {
      programs.mosh.enable = true;
    }
    {
      services.dnsmasq = {
        enable = true;
    
        # These are used in addition to resolv.conf
        servers = [
          "/cybervisiontech.com/10.2.2.45"
          "/kaaiot.io/10.2.2.45"
          "8.8.8.8"
          "8.8.4.4"
        ];
    
        extraConfig = ''
          listen-address=127.0.0.1
          cache-size=1000
    
          no-negcache
        '';
      };
    
      # Put the text in /etc/resolv.conf.head
      #
      # That will prepend dnsmasq server to /etc/resolv.conf (dhcpcd-specific)
      environment.etc."resolv.conf.head".text = ''
        nameserver 127.0.0.1
      '';
    
      # dhclient-specific.
      #
      # This prepends local dnsmasq to the list of domain name servers.
      #
      # The supersede host-name line resolves the issue when DHCP overrides my machine name.
      # For more info, see https://support.cumulusnetworks.com/hc/en-us/articles/218289767-Hostname-Configured-in-etc-hostname-Is-Superseded-by-the-DHCP-hostname-Option-
      systemd.services.wicd.preStart = let
        dhclient_conf_template = pkgs.writeText "dhclient.conf.template" ''
          prepend domain-name-servers 127.0.0.1;
          supersede host-name "$_HOSTNAME";
        '';
      in ''
        mkdir -p /var/lib/wicd/
        cp ${dhclient_conf_template} /var/lib/wicd/dhclient.conf.template
      '';
    }
    {
      networking.firewall = {
        enable = true;
        allowPing = false;
    
        connectionTrackingModules = [];
        autoLoadConntrackHelpers = false;
      };
    }
    {
      virtualisation.virtualbox.host.enable = true;
      users.extraUsers.rasen.extraGroups = [ "vboxusers" ];
    }
    {
      environment.systemPackages = [
        pkgs.isyncUnstable
      ];
    }
    {
      services.dovecot2 = {
        enable = true;
        enablePop3 = false;
        enableImap = true;
        mailLocation = "maildir:~/Mail:LAYOUT=fs";
      };
    
      # dovecot has some helpers in libexec (namely, imap).
      environment.pathsToLink = [ "/libexec/dovecot" ];
    }
    {
      environment.systemPackages = [
        pkgs.msmtp
      ];
    }
    {
      environment.systemPackages = [
        pkgs.notmuch
      ];
    }
    {
      services.xserver.enable = true;
    }
    {
      i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    }
    {
      time.timeZone = "Europe/Kiev";
    }
    {
      services.xserver.displayManager.slim.enable = true;
    }
    {
      services.xserver.windowManager.awesome = {
        enable = true;
        luaModules = [ pkgs.luaPackages.luafilesystem pkgs.luaPackages.cjson ];
      };
    }
    {
      services.xserver.desktopManager.xterm.enable = false;
    }
    {
      environment.systemPackages = [
        pkgs.wmname
        pkgs.xclip
        pkgs.scrot
      ];
    }
    {
      services.xserver.layout = "us,ua";
      services.xserver.xkbVariant = "workman,";
    
      # Use same config for linux console
      i18n.consoleUseXkbConfig = true;
    }
    {
      services.xserver.xkbOptions = "grp:caps_toggle,grp:menu_toggle,grp_led:caps";
    }
    {
      environment.systemPackages = [ pkgs.xcape ];
    }
    {
      services.redshift = {
        enable = true;
        latitude = "50.4500";
        longitude = "30.5233";
      };
    }
    {
      environment.systemPackages = [
        pkgs.oxygen-icons5
      ];
    }
    (let
      oldpkgs = import (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        rev = "1aa77d0519ae23a0dbef6cab6f15393cfadcc454";
        sha256 = "1gcd8938n3z0a095b0203fhxp6lddaw1ic1rl33q441m1w0i19jv";
      }) { config = config.nixpkgs.config; };
    in {
      environment.systemPackages = [ oldpkgs.oxygen-gtk2 oldpkgs.oxygen-gtk3 ];
    
      environment.shellInit = ''
        export GTK_PATH=$GTK_PATH:${oldpkgs.oxygen_gtk}/lib/gtk-2.0
        export GTK2_RC_FILES=$GTK2_RC_FILES:${oldpkgs.oxygen_gtk}/share/themes/oxygen-gtk/gtk-2.0/gtkrc
      '';
    })
    {
      environment.systemPackages = [
        pkgs.gnome3.adwaita-icon-theme
      ];
    }
    {
      fonts = {
        enableCoreFonts = true;
        enableFontDir = true;
        enableGhostscriptFonts = false;
    
        fonts = with pkgs; [
          inconsolata
          corefonts
          dejavu_fonts
          source-code-pro
          ubuntu_font_family
          unifont
        ];
      };
    }
    {
      environment.systemPackages = [
        pkgs.gwenview
        pkgs.dolphin
        pkgs.kde4.kfilemetadata
        pkgs.filelight
        pkgs.shared_mime_info
      ];
    }
    {
      environment.pathsToLink = [ "/share" ];
    }
    {
      nixpkgs.config.firefox = {
        icedtea = true;
      };
    
      environment.systemPackages = [ pkgs.firefox-esr ];
    }
    {
      environment.systemPackages = [
        pkgs.zathura
      ];
    }
    {
      security.wrappers = {
        slock = {
          source = "${pkgs.slock}/bin/slock";
        };
      };
    }
    {
      environment.systemPackages = [
        pkgs.google-chrome
        pkgs.skype
        pkgs.libreoffice
        pkgs.qbittorrent
        pkgs.calibre
        pkgs.mnemosyne
        pkgs.deadbeef
        pkgs.wine
        pkgs.vlc
        pkgs.mplayer
        pkgs.smplayer
        pkgs.gparted
        pkgs.unetbootin
        pkgs.kvm
        pkgs.thunderbird
        pkgs.xss-lock
        pkgs.alarm-clock-applet
        pkgs.pass
    
        # Used by naga setup
        pkgs.xdotool
      ];
    }
    {
      environment.systemPackages = [
        (pkgs.vim_configurable.override { python3 = true; })
        pkgs.emacs
      ];
    }
    {
      environment.systemPackages = [
        pkgs.ycmd
        pkgs.rustracer
        pkgs.ditaa
        pkgs.jre
      ];
    }
    {
      environment.systemPackages = [
        pkgs.rxvt_unicode
      ];
    }
    {
      fonts = {
        fonts = [
          pkgs.powerline-fonts
          pkgs.terminus_font
        ];
      };
    }
    {
      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    }
    {
      environment.systemPackages = [
        pkgs.qrencode
        pkgs.feh
      ];
    }
    {
      programs.zsh.enable = true;
    }
    {
      environment.systemPackages = [
        pkgs.gitFull
        pkgs.gitg
      ];
    }
    {
      environment.systemPackages = [
        pkgs.tmux
      ];
    }
    {
      environment.systemPackages = [
        pkgs.minicom
        pkgs.openocd
        pkgs.telnet
        pkgs.saleae-logic
      ];
    }
    {
      users.extraGroups.plugdev = { };
      users.extraUsers.rasen.extraGroups = [ "plugdev" "dialout" ];
    
      services.udev.packages = [ pkgs.openocd ];
    }
    {
      environment.systemPackages = [
        pkgs.wget
        pkgs.htop
        pkgs.psmisc
        pkgs.zip
        pkgs.unzip
        pkgs.unrar
        pkgs.p7zip
        pkgs.irssi
        pkgs.bind
        pkgs.file
        pkgs.which
        pkgs.whois
        pkgs.gnupg
        pkgs.utillinuxCurses
    
        pkgs.patchelf
    
        pkgs.nix-repl
        pkgs.nox
    
        pkgs.python
        pkgs.python3
      ];
    }
    {
      environment.systemPackages = [
        pkgs.steam
      ];
    }
    {
      hardware.opengl.driSupport32Bit = true;
      hardware.pulseaudio.support32Bit = true;
    }
    {
      environment.systemPackages = [
        pkgs.nethack
      ];
    }
  ] ++ machine-config;
}

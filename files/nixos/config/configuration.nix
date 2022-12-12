{ config, pkgs, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/profiles/headless.nix>
    ./hardware-configuration.nix
    ./hcloud
  ];

  system.stateVersion = "{{ NIX_CHANNEL }}";

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [
    neovim
  ];

  i18n.defaultLocale = lib.mkDefault "{{ LOCALE }}";
  console.keyMap = lib.mkDefault "{{ KEYMAP }}";
  time.timeZone = lib.mkDefault "{{ TIMEZONE }}";

  boot = {
    tmpOnTmpfs = lib.mkDefault true;
    loader.grub.device = lib.mkDefault "/dev/sda";

    initrd.luks.devices = {
      root = {
        device = "/dev/sda2";
        preLVM = true;
      };
    };
  };

  system.autoUpgrade.enable = lib.mkDefault true;

  nix = {
    settings.auto-optimise-store = lib.mkDefault true;

    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "daily";
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };

  networking.dhcpcd.enable = lib.mkDefault true;

  services.resolved.enable = lib.mkDefault true;

  services.openssh.enable = lib.mkDefault true;
  users.users.root.openssh.authorizedKeys.keys = lib.mkDefault [
    "{{ ROOT_SSH_KEY }}"
  ];
}

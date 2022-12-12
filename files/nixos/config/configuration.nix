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

  console.keyMap = "us";
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

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

  networking.dhcpcd.enable = lib.mkDefault true;

  services.openssh.enable = lib.mkDefault true;
  users.users.root.openssh.authorizedKeys.keys = lib.mkDefault [
    "{{ ROOT_SSH_KEY }}"
  ];
}

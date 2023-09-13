{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    initrd = {
      availableKernelModules = [ "ahci" "sd_mod" "r8169" ];
      luks.devices."data".device = "/dev/disk/by-uuid/db20b995-5cab-45ae-b1b9-0ba20a73eda6";
    };
    swraid.mdadmConf = "MAILADDR root";
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/4328df85-8112-495a-ba18-2b23d6fa54e2";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };
  
  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/4328df85-8112-495a-ba18-2b23d6fa54e2";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };
  
  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/4328df85-8112-495a-ba18-2b23d6fa54e2";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };
  
  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/4328df85-8112-495a-ba18-2b23d6fa54e2";
      fsType = "btrfs";
      options = [ "subvol=var" ];
    };
  
  fileSystems."/swap" =
    { device = "/dev/disk/by-uuid/4328df85-8112-495a-ba18-2b23d6fa54e2";
      fsType = "btrfs";
      options = [ "subvol=swap" ];
    };
  
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/22528ebc-c073-447d-a2cb-74854cc11a19";
      fsType = "ext4";
    };
  
  fileSystems."/boot-fallback" =
    { device = "/dev/disk/by-uuid/1da184b8-3e1c-4492-9bc1-fd04a2d0e343";
      fsType = "ext4";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}

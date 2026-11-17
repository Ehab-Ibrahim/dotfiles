# Disk layout for `horus`, applied by disko (wipes the disk on install).
# ~72G of the volume group is left unallocated so root or /srv can grow
# online later: sudo lvextend -r -L +20G /dev/pool/root
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-CT1000MX500SSD1_2114E593390F";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          lvm = {
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          };
        };
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "50G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          size = "8G";
          content.type = "swap";
        };
        srv = {
          size = "800G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/srv";
          };
        };
      };
    };
  };
}

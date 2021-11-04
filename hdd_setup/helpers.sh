#!/bin/sh

fatal_error() 
{
  echo "FATAL | $1 | $2" >&2
  exit 1
}

check_error() 
{
  if [ $? -ne 0 ]; then
    fatal_error $1 $2
  fi
}

must_be_root()
{
  if [ ${EUID} -ne 0 ]; then
    fatal_error $1 "The script must be executed as root."
  fi
}

print_info()
{
  echo "INFO | $1 | $2" >&1
}

make_gpt()
{
  echo "Creating GPT partition table on $1....."
  parted -s $1 mklabel gpt
  check_error ${LINENO} "Failed to create GPT partition table on $1."
}


# $1 = HDD
# $2 = Partition
# $3 = Start
# $4 = End
create_pv()
{
  parted -s -a optimal $1$2 primary $3 $4
  parted -s $1 set $2 lvm on
  pvcraete $1$2
}

# $1 = Size
# $2 = Logical Volume Name
# $3 = Volume Group Name
# $4 = File System
create_lv()
{
  lvcreate -L $1 -n $2 
}


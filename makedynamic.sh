#!/bin/bash
#!/I got this script from https://sourceforge.net/projects/helios-gsis/, all credits for him! Good work and good usage. (modded, and broken, wait for my fix)

#Variables

PARTITIONS=("system" "product" "opproduct")
payload_extractor="payload/payload_dumper.py"
LOCALDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
outdir="$LOCALDIR/cache"
tmpdir="$outdir/tmp"
#############################################################

usage() {
    echo "Usage: $0 <Firmware Type> [Path to Firmware]"
    echo -e "\tFirmware Type! = OxygenOS or Pixel"
    echo -e "\tPath to Firmware!"
}

if [ "$1" == "" ]; then
    echo "Enter all needed parameters"
    usage
    exit 1
fi

echo "Create Temp and out dir"
	mkdir -p "$tmpdir"
	mkdir -p "$outdir"

unzip $2 -d $tmpdir &> /dev/null
echo "Extracting Required Partitions . . . . "
if [ $1 = "OxygenOS" ]; then
		for partition in ${PARTITIONS[@]}; do
 	   	    python3 $payload_extractor --partitions $partition --output_dir $tmpdir $tmpdir/payload.bin 
		done
	mv $tmpdir/system $outdir/system-old.img
	mv $tmpdir/product $outdir/product.img
	mv $tmpdir/opproduct $outdir/opproduct.img
elif [ $1 = "Pixel" ]; then
	unzip $tmpdir/*/*.zip -d $tmpdir &> /dev/null
	simg2img $tmpdir/system.img $outdir/system-old.img
	simg2img $tmpdir/product.img $outdir/product.img
fi
rm -rf $tmpdir
echo "Creating Dummy System Image . . . . "
dd if=/dev/zero of=$outdir/system.img bs=4k count=1048576
mkfs.ext4 $outdir/system.img
tune2fs -c0 -i0 $outdir/system.img
echo "Mounting System Images . . . . "
	mkdir system
	mkdir system-old
	mount -o loop $outdir/system.img system/
	mount -o ro $outdir/system-old.img system-old/
	echo "  "
echo "Copying Files . . . . "
	cp -v -r -p system-old/* system/ &> /dev/null
	sync
	umount system-old
	rm $outdir/system-old.img
	rm -rf system/product
	ln -s system/product system/product
    	rm -rf system/system/product
    	mkdir system/system/product/
echo "Merging product.img "
	sudo mkdir $outdir/product
	mount -o ro $outdir/product.img $outdir/product/
	cp -v -r -p $outdir/product/* system/system/product/ &> /dev/null
	sync
	umount $outdir/product
	rmdir $outdir/product/
	rm $outdir/product.img
if [ $1 = "OxygenOS" ]; then
	echo "Merging opproduct.img "
	sudo mkdir $outdir/opproduct
	mount -o ro $outdir/opproduct.img $outdir/opproduct/
	cp -v -r -p $outdir/opproduct/* system/oneplus/ &> /dev/null
	sync
	umount $outdir/opproduct
	rmdir $outdir/opproduct/
	rm $outdir/opproduct.img
fi
echo "Finalising "
	mkdir out
	rm -rf system-old/
echo "Please finish creating GSI using make.sh script"
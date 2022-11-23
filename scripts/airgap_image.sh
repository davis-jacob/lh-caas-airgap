#!/bin/bash
### Get the Domain name
printf "Enter the domain name for the Harbor\n"
read -p "Harbor Domain Name :" domain
printf "\n\n"

### Get the releases version
printf "$(hpe-airgap-util --list_releases |awk '{print $1}')"
printf "\nThese are the available Release versions \n"
printf "Enter the release version from the above list \n"
read -p "Release Verion :" version
printf "\n\n"

### Get the image list
touch /tmp/list.txt
cat /dev/null > /tmp/list.txt
printf "$(hpe-airgap-util --release "$version" |awk '{print $1}')" > /tmp/list.txt

### Get the total number of image
total=$(wc -l /tmp/list.txt | awk '{print $1}')

### Set files to empty
touch /tmp/image_error.txt
touch /tmp/image_success.txt
touch /tmp/copy_fail.txt
cat /dev/null > /tmp/image_error.txt
cat /dev/null > /tmp/image_success.txt
cat /dev/null > /tmp/copy_fail.txt
count=0
count1=0

###  Read each line from the image list and copy to the local Harbor
input="/tmp/list.txt"
while read -r line;
do
  ((count+=1))
  echo "Coping image "$count" out of "$total""
  error_image=$((hpe-airgap-util --release "$version"  --copy --dest_url harbor."$domain"/airgap --image "$line" --dest_creds 'admin:Password!234' | grep  -i error) 2>&1 > /dev/null)
  if [ -z "$error_image" ];
  then
    echo "$line" >> /tmp/image_success.txt

  else

    echo "$line" >> /tmp/image_error.txt
  fi
done < "$input"

fail_total=$(wc -l /tmp/image_error.txt | awk '{print $1}')

### Re-running copy for failed images
if [ -s /tmp/image_error.txt ]; then
  # The file is not-empty.

  input="/tmp/image_error.txt"
  while read -r line;
  do
    ((count1+=1))
    echo "Coping image "$count1" out of "$fail_total""
    error_image1=$((hpe-airgap-util --release "$version"  --copy --dest_url harbor.gl-hpe.local/airgap --image "$line" --dest_creds 'admin:Password!234' | grep  -i error) 2>&1 > /dev/null)
    if [ -z "$error_image1" ];then
      echo "$line" >> /tmp/image_success.txt
    else
      echo "$line" >> /tmp/copy_fail.txt
    fi
  done < "$input"
fi

### Result of Image Copy
succes_total=$(wc -l /tmp/image_success.txt | awk '{print $1}')
fail_total=$(wc -l /tmp/copy_fail.txt | awk '{print $1}')


### Print result of Copy
printf "\nSuccessfully copied  "$succes_total" images out of $total, list available at /tmp/image_success.txt\n\n"

if [ -s /tmp/copy_fail.txt ]; then
printf "\n\nFailed to copy "$fail_total" image, list available at /tmp/copy_fail.txt\n\n"
printf "\n\nRun the following command for the failed images 'hpe-airgap-util --release 5.4.3-3077  --copy --dest_url harbor.gl-hpe.local/airgap --image <image_name> --dest_creds 'admin:Password!234'\n\n"
else
printf "\n\n All images copied to the local harbor \n\n"
fi


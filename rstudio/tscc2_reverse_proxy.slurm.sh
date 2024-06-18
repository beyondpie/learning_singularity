#!/usr/bin/env bash

#SBATCH --job-name=rstudio
#SBATCH --account=use300
#SBATCH --qos=condo
#SBATCH --partition=condo
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=1:30:00
#SBATCH --export=ALL
#SBATCH --output=rstudio.o%j.%N


declare -xr REVERSE_PROXY_FQDN='tscc-user-content.sdsc.edu'
declare -xr PRIVATE_DNS_DOMAIN='local'
#declare -xr PRIVATE_IP_ADDRESS="$(host "$(hostname -s).${PRIVATE_DNS_DOMAIN}" | awk '{print $4}')"
declare -xr PRIVATE_IP_ADDRESS="$(nslookup $SLURM_NODELIST | grep Address | grep -v "#" | awk -F ": " '{print $2}')"

declare -xi PORT_NUMBER=-1
declare -xir LOWEST_EPHEMERAL_PORT=49152
declare -i random_ephemeral_port=-1

#declare -xr SINGULARITY_MODULE='singularitypro'

module purge
module load slurm
module load cpu/0.17.3
module load singularitypro
module list
#printenv

# Find an open ephemeral port (randomly).
while (( "${PORT_NUMBER}" < 0 )); do
  while (( "${random_ephemeral_port}" < "${LOWEST_EPHEMERAL_PORT}" )); do
    random_ephemeral_port="$(od -An -N 2 -t u2 -v < /dev/urandom)"
  done
  ss -nutlp | cut -d : -f2 | grep "^${random_ephemeral_port})" > /dev/null
  if [[ "${?}" -ne 0 ]]; then
    PORT_NUMBER="${random_ephemeral_port}"
  fi
done


# Request a subdomain connection token from reverse proxy service. If the
# reverse proxy service returns an HTTP/S error, then halt the launch.
http_response="$(curl -s -w %{http_code} https://manage.${REVERSE_PROXY_FQDN}/getlink.cgi -o -)"
http_status_code="$(echo ${http_response} | awk '{print $NF}')"
if (( "${http_status_code}" != 200 )); then
    echo "Unable to connect to the Satellite reverse proxy service: ${http_status_code}"
  return 1
fi

# Extract the reverse proxy connection token and export it as a
# read-only environment variable.
declare -xr REVERSE_PROXY_TOKEN="$(echo ${http_response} | awk 'NF>1{printf $((NF-1))}' -)"

# Launch RStudio within Singularity container
singularity exec --bind /tscc/projects,/tscc/lustre,run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf /cm/shared/apps/containers/test/rstudio-4.3.2.sif rserver --server-user=$(whoami) --www-address=${PRIVATE_IP_ADDRESS} --www-port=${PORT_NUMBER} &

# Redeem connection token.
curl "https://manage.${REVERSE_PROXY_FQDN}/redeemtoken.cgi?token=${REVERSE_PROXY_TOKEN}&port=${PORT_NUMBER}"

# Print URL to file for user.
echo "https://${REVERSE_PROXY_TOKEN}.${REVERSE_PROXY_FQDN}" > "rstudio-https-url.${SLURM_JOB_ID}"

wait

# Destroy token when job ends.
curl "https://manage.${REVERSE_PROXY_FQDN}/destroytoken.cgi?token=${REVERSE_PROXY_TOKEN}" 

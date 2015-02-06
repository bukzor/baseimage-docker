#!/bin/bash
set -e

function abort()
{
	echo "$@"
	exit 1
}

function cleanup()
{
	echo " --> Stopping container"
	docker stop $ID >/dev/null
	docker rm $ID >/dev/null
}

PWD=`pwd`

echo " --> Starting insecure container"
ID=`docker run --env=AUTHORIZED_KEYS="$(ssh-add -L)" -d -v $PWD/test:/test $NAME:$VERSION`

echo " --> Obtaining IP"
IP=`docker inspect --format='{{ .NetworkSettings.IPAddress }}' $ID`
if [[ "$IP" = "" ]]; then
	abort "Unable to obtain container IP"
fi

trap cleanup EXIT

echo " --> Waiting for services"
docker exec $ID /sbin/wait-for-services

echo " --> Enabling SSH in the container"
docker exec $ID sv start /etc/service/sshd

echo " --> Logging into container and running tests"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP \
	/bin/bash /test/test.sh

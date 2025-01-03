#!/bin/bash

# Variables
SERVER1_IP="IP_SERVER_1" # آدرس IP سرور 1
SERVER2_IP="IP_SERVER_2" # آدرس IP سرور 2
OPENVPN_PORT=1194        # پورت OpenVPN

# Install OpenVPN on both servers
echo "Installing OpenVPN on both servers..."
ssh root@$SERVER1_IP "apt update && apt install -y openvpn easy-rsa"
ssh root@$SERVER2_IP "apt update && apt install -y openvpn easy-rsa"

# Configure Server 2 as OpenVPN Server
echo "Configuring Server 2 as OpenVPN server..."
ssh root@$SERVER2_IP <<EOF
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
./easyrsa gen-crl
cp pki/ca.crt pki/dh.pem pki/private/server.key pki/issued/server.crt /etc/openvpn/
cat > /etc/openvpn/server.conf <<EOL
port $OPENVPN_PORT
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"
keepalive 10 120
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
EOL
systemctl enable openvpn@server
systemctl start openvpn@server
EOF

# Configure Server 1 as OpenVPN Client
echo "Configuring Server 1 as OpenVPN client..."
ssh root@$SERVER2_IP "cat /etc/openvpn/pki/ca.crt" > ca.crt
scp root@$SERVER1_IP:/etc/openvpn/easy-rsa/pki/private/client.key client.key
scp root@$SERVER1_IP:/etc/openvpn/easy-rsa/pki/issued/client.crt client.crt
ssh root@$SERVER1_IP <<EOF
cat > /etc/openvpn/client.conf <<EOL
client
dev tun
proto udp
remote $SERVER2_IP $OPENVPN_PORT
ca /etc/openvpn/ca.crt
cert /etc/openvpn/client.crt
key /etc/openvpn/client.key
persist-key
persist-tun
redirect-gateway def1
verb 3
EOL
systemctl enable openvpn@client
systemctl start openvpn@client
EOF

echo "OpenVPN setup completed. Server 1 is now tunneling traffic to Server 2."

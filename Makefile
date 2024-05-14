CHIRPSTACK_GATEWAY_BRIDGE_HOSTS ?= 127.0.0.1,localhost

import-lorawan-devices:
	docker-compose run --rm --entrypoint sh --user root chirpstack -c '\
		apk add --no-cache git && \
		git clone https://github.com/brocaar/lorawan-devices /tmp/lorawan-devices && \
		chirpstack -c /etc/chirpstack import-legacy-lorawan-devices-repository -d /tmp/lorawan-devices'

make: certs/ca \
	certs/chirpstack-gateway-bridge/basicstation \
	certs/mqtt-broker

set-hosts:
	./set-hosts.sh config/chirpstack-gateway-bridge/basicstation/certificate.json $(CHIRPSTACK_GATEWAY_BRIDGE_HOSTS)

docker:
	docker compose run --rm chirpstack-certificates

clean:
	rm -rf certs

certs/ca:
	mkdir -p certs/ca
	cfssl gencert -initca config/ca-csr.json | cfssljson -bare certs/ca/ca

certs/chirpstack-gateway-bridge/basicstation: certs/ca
	mkdir -p certs/chirpstack-gateway-bridge/basicstation

	# basicstation websocket server certificate
	cfssl gencert -ca certs/ca/ca.pem -ca-key certs/ca/ca-key.pem -config config/ca-config.json -profile server config/chirpstack-gateway-bridge/basicstation/certificate.json | cfssljson -bare certs/chirpstack-gateway-bridge/basicstation/basicstation

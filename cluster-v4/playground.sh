# create the new HA cluster
kind create cluster --name ha-cluster-v4 --config kind-config.yaml

# debug with more logs
kubectl version --v=7

# aggregator extension
apiVersion: v1
data:
  client-ca-file: |
    -----BEGIN CERTIFICATE-----
    MIIC5zCCAc+gAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
    cm5ldGVzMB4XDTIxMTAyNDA1MzE1NVoXDTMxMTAyMjA1MzE1NVowFTETMBEGA1UE
    AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKM/
    mPBxU0Ri/RL8fbgjOi+a3ALeUqbuF/AFocIGra7YMjavxw0xpr8W35gjkkHkqlnF
    IuJrBklUW9wmbYTwHxuBdC+KD2lrA/0N4mIeQhpJAPv/exDyNbTr4WND2oGUU194
    yv2UALygyXuegD8z4/ezDGy+LvJHIYslNNeh8Z4azSGNmZVzqcpOuq8M/+Gq2QJS
    es8r9SLdp1zrG3GAUOWKl1VWxrSAeQtj9SShnzkydJMgyrWOh1oKwQaYoHK1TskB
    1koeXD7gbbUTLcelEK3I6aNTvvD5leyuCOcS688B/qsHzZEH8A/ekqUhqM0lgBaM
    +X03zx3YrmpA0N4xQ5cCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
    /wQFMAMBAf8wHQYDVR0OBBYEFIrI300WfUtklugYmCSBAFk0MGSLMA0GCSqGSIb3
    DQEBCwUAA4IBAQAKV8mFV41vuXX7FgfKDm57siUtrg2l9YW1NToLxKUXCUwmYEE+
    ycUSbDJTI0K9BwiPdq93VZt7UbeaBwcxlA6bv4EtevUmOOs7ZZSzGw9h6gKgneyQ
    tvKe/YIB79/4SxrKML35rq9cQ6D/Q9iy8p08G156x+U/FqhNwBChUYIRm3jEjSgG
    xAmbtmofKvi0hsWegGM31fRSqg6u+8tgr+kjGwKXH6gvYDiWrcrMVDmMBcmp1TzL
    MLgALjNmu6JVgX5Pf1ihmlYuJKRW3nP3wjSMzTXOoXfgj/SLyZLHzYzKHUg5ieCt
    tIok7NRwVuUr/MHrPXvhGKFA//Sx8P04UQW1
    -----END CERTIFICATE-----
  requestheader-allowed-names: '["front-proxy-client"]'
  requestheader-client-ca-file: |
    -----BEGIN CERTIFICATE-----
    MIIC7zCCAdegAwIBAgIBADANBgkqhkiG9w0BAQsFADAZMRcwFQYDVQQDEw5mcm9u
    dC1wcm94eS1jYTAeFw0yMTEwMjQwNTMxNTZaFw0zMTEwMjIwNTMxNTZaMBkxFzAV
    BgNVBAMTDmZyb250LXByb3h5LWNhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
    CgKCAQEAvYFyBdGXaj5zABVwSH3+21LcJDY7XIWLGRnDgGZVXpAcBCeWyKxD2ADl
    GT9GImZvAd7zKD+Ij4pTVDf8K0hs0ok5FGzw2T1R1ktPkJnRDfL0vX2Nmxte1Ykh
    BfJxP8qKg03aqx2LQt2SU4azZgtfLJz5BcBcXo5ZdKlQLP2yuThld9EzipNSCYz/
    dxEpt00sPSaDdmS6VRgCmpzhHwjpeDM1Y1ngsdaDN7vItC/grYR4UwGvYYz5WicS
    4zvQ4Y21vM+rR3Wf3YKnBX2BSO3b0QEHkZ/nJ7Lt3IIh+kE4ATIucr2oscsmtQM6
    4cNcuBM+5AaAWkkYkxS6KLLSbN0GawIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAqQw
    DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUkkE7/21oSR4dEJw1c56QZzws39cw
    DQYJKoZIhvcNAQELBQADggEBALRsXCLHJRs9xXWz+KjEid+Y93ipwfL9pMK6cBl9
    kt2Gv7ZZrn775cyxDm3G07hicpIFTCLfAd3rNaCRh8/TbBw3YVP7hXHqN2CuRMDX
    OMiOGHGYfcKnfC/xV2T6aw3Yl4inpEVsoXmh3JKOXA7iT7+w5RiXQbr5utQPqG4T
    XFrmnPYrL6mBiwXGHgaZBcYDHAl41ovCh23eaGYB88ujD+yVMoa3wFD6yIx1kzHh
    48EIusoyMOqpRX/K30TEzuzjSXj6z6Wjrf/jm2bp8o5Jx+7Heh/RD6TurC+VxUtw
    xg0uT/i5Dy5ZCVA4/XrANcPpqiSZACqmcxoyzI48W0uI15U=
    -----END CERTIFICATE-----
  requestheader-extra-headers-prefix: '["X-Remote-Extra-"]'
  requestheader-group-headers: '["X-Remote-Group"]'
  requestheader-username-headers: '["X-Remote-User"]'
kind: ConfigMap
metadata:
  creationTimestamp: "2021-10-24T05:32:12Z"
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:data:
        .: {}
        f:client-ca-file: {}
        f:requestheader-allowed-names: {}
        f:requestheader-client-ca-file: {}
        f:requestheader-extra-headers-prefix: {}
        f:requestheader-group-headers: {}
        f:requestheader-username-headers: {}
    manager: kube-apiserver
    operation: Update
    time: "2021-10-24T05:32:12Z"
  name: extension-apiserver-authentication
  namespace: kube-system
  resourceVersion: "36"
  uid: b088ea7d-d98f-48c2-9a71-eeff316dfd49


#   CNI
{
	"cniVersion": "0.3.1",
	"name": "kindnet",
	"plugins": [
	{
		"type": "ptp",
		"ipMasq": false,
		"ipam": {
			"type": "host-local",
			"dataDir": "/run/cni-ipam-state",
			"routes": [


				{ "dst": "0.0.0.0/0" }
			],
			"ranges": [
				[ { "subnet": "10.244.2.0/24" } ]
			]
		}
		,
		"mtu": 1500

	},
	{
		"type": "portmap",
		"capabilities": {
			"portMappings": true
		}
	}
	]
}

--v=${LOG_LEVEL} \
      --vmodule="${LOG_SPEC}" \
      --cert-dir="${CERT_DIR}" \
      --client-ca-file="${CERT_DIR}/client-ca.crt" \
      --kubelet-client-certificate="${CERT_DIR}/client-kube-apiserver.crt" \
      --kubelet-client-key="${CERT_DIR}/client-kube-apiserver.key" \
      --service-account-key-file="${SERVICE_ACCOUNT_KEY}" \
      --service-account-lookup="${SERVICE_ACCOUNT_LOOKUP}" \
      --enable-admission-plugins="${ENABLE_ADMISSION_PLUGINS}" \
      --disable-admission-plugins="${DISABLE_ADMISSION_PLUGINS}" \
      --admission-control-config-file="${ADMISSION_CONTROL_CONFIG_FILE}" \
      --bind-address="${API_BIND_ADDR}" \
      --secure-port="${API_SECURE_PORT}" \
      --tls-cert-file="${CERT_DIR}/serving-kube-apiserver.crt" \
      --tls-private-key-file="${CERT_DIR}/serving-kube-apiserver.key" \
      --insecure-bind-address="${API_HOST_IP}" \
      --insecure-port="${API_PORT}" \
      --storage-backend=${STORAGE_BACKEND} \
      --storage-media-type=${STORAGE_MEDIA_TYPE} \
      --etcd-servers="http://${ETCD_HOST}:${ETCD_PORT}" \
      --service-cluster-ip-range="${SERVICE_CLUSTER_IP_RANGE}" \
      --feature-gates="${FEATURE_GATES}" \
      --external-hostname="${EXTERNAL_HOSTNAME}" \
      --requestheader-username-headers=X-Remote-User \
      --requestheader-group-headers=X-Remote-Group \
      --requestheader-extra-headers-prefix=X-Remote-Extra- \
      --requestheader-client-ca-file="${CERT_DIR}/request-header-ca.crt" \
      --requestheader-allowed-names=system:auth-proxy \
      --proxy-client-cert-file="${CERT_DIR}/client-auth-proxy.crt" \
      --proxy-client-key-file="${CERT_DIR}/client-auth-proxy.key" \
      --cors-allowed-origins="${API_CORS_ALLOWED_ORIGINS}" >"${APISERVER_LOG}" 2





      # ###############
      {

cat > proxy-client-ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > proxy-client-ca-csr.json <<EOF
{
  "CN": "proxyClientCA",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}

cat > admin-csr.json <<EOF
{
  "CN": "system:auth-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:auth-proxy",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
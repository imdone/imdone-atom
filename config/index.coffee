dev =
  name: "localhost",
  imdoneKeyA: 'NjbOJJ42rA4zdkEE8gs-D_USeA-_iUa9tpZLOFwKcGEh9PymSSP9zw=='
  imdoneKeyB: 'ZHpAmF5D8S_7lVuDNP--hgJGncY='
  pusherKey:  '64354707585286cfe58f'
  pusherChannelPrefix: 'private-imdoneio-dev'
  baseUrl: 'http://localhost:3000'

beta =
  name: 'beta.imdone.io'
  imdoneKeyA: 'WFuE-QDFbrN5lip0gdHyYAdXDMdZPerXFey02k93dn-HOYJXoAAdBA=='
  imdoneKeyB: 'ALnfTYYEtghJBailJ1n-7tx4hIo='
  pusherKey:  '0a4f9a6c45def222ab08'
  pusherChannelPrefix: 'private-imdoneio-beta'
  baseUrl:    'https://beta.imdone.io'

# TODO: Change these prior to release
prod =
  name: 'imdone.io'
  imdoneKeyA: 'BcbpJqNyYvAI5FhR-dt5AbdcpXKV8gj0vv0RHjb1qGCXoymcckb8hQ=='
  imdoneKeyB: 'EUyEtV2d-ZSgvvWKGlCiOVvAmlc='
  pusherKey:  '64354707585286cfe58f'
  baseUrl:    'https://imdone.io'
  pusherChannelPrefix: 'private-imdoneio-dev'

module.exports = beta
  # if /dev/i.test process.env.IMDONE_ENV then dev
  # else if /beta/i.test process.env.IMDONE_ENV then beta
  # else prod

dev =
  imdoneKeyA: 'NjbOJJ42rA4zdkEE8gs-D_USeA-_iUa9tpZLOFwKcGEh9PymSSP9zw=='
  imdoneKeyB: 'ZHpAmF5D8S_7lVuDNP--hgJGncY='
  pusherKey:  '64354707585286cfe58f'
  pusherChannelPrefix: 'private-imdoneio-dev'
  baseUrl:    'http://localhost:3000'

# TODO:50 Change these prior to release id:2
prod =
  imdoneKeyA: 'BcbpJqNyYvAI5FhR-dt5AbdcpXKV8gj0vv0RHjb1qGCXoymcckb8hQ=='
  imdoneKeyB: 'EUyEtV2d-ZSgvvWKGlCiOVvAmlc='
  pusherKey:  '64354707585286cfe58f'
  baseUrl:    'http://imdone.io'
  pusherChannelPrefix: 'private-imdoneio-dev'

module.exports = if /dev/i.test process.env.IMDONE_ENV then dev else prod

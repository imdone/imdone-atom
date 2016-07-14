dev =
  imdoneKeyA: 's_vYimF_tDlkxs1hElBVtcBdUmeJzjp8ZdSL1m8CLydEQAatrvSydA=='
  imdoneKeyB: 'YB0YXmQt6koy5-EdEb9tYFXSdr0='
  pusherKey:  '64354707585286cfe58f'
  pusherChannelPrefix: 'private-imdoneio-dev'
  baseUrl:    'http://localhost:3000'

# TODO: Change these prior to release id:568
prod =
  imdoneKeyA: 'BcbpJqNyYvAI5FhR-dt5AbdcpXKV8gj0vv0RHjb1qGCXoymcckb8hQ=='
  imdoneKeyB: 'EUyEtV2d-ZSgvvWKGlCiOVvAmlc='
  pusherKey:  '64354707585286cfe58f'
  baseUrl:    'http://imdone.io'
  pusherChannelPrefix: 'private-imdoneio-dev'

module.exports = if /dev/i.test process.env.IMDONE_ENV then dev else prod

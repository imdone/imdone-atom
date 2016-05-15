dev =
  imdoneKeyA: 'W6BYGwi1Plfy7b8BbduAzK2fQ0nIJ1y23ToIDT_8-QZm20AcXBWUCQ=='
  imdoneKeyB: 'i3QJvKQesKwFdSxlwoQOW_B5UZw='
  pusherKey:  '64354707585286cfe58f'
  pusherChannelPrefix: 'private-imdoneio-dev'
  baseUrl:    'http://localhost:3000'

# TODO:20 Change these prior to release
prod =
  imdoneKeyA: 'W6BYGwi1Plfy7b8BbduAzK2fQ0nIJ1y23ToIDT_8-QZm20AcXBWUCQ=='
  imdoneKeyB: 'i3QJvKQesKwFdSxlwoQOW_B5UZw='
  pusherKey:  '64354707585286cfe58f'
  baseUrl:    'http://imdone.io'
  pusherChannelPrefix: 'private-imdoneio-dev'

module.exports = if /dev/i.test process.env.IMDONE_ENV then dev else prod

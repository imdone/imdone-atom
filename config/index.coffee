dev =
  imdoneKeyA: 'GfBC8vMo5JpLufoQjm4236_1mVTocolClAXFsTjcM6ZQ7MAHS8pMEQ=='
  imdoneKeyB: 'TShVzu_bjjuEUlC1ulTSvb4Qn0Y='
  pusherKey:  '64354707585286cfe58f'
  pusherChannelPrefix: 'private-imdoneio-dev'
  baseUrl:    'http://localhost:3000'

# TODO:0 Change these prior to release
prod =
  imdoneKeyA: 'GfBC8vMo5JpLufoQjm4236_1mVTocolClAXFsTjcM6ZQ7MAHS8pMEQ=='
  imdoneKeyB: 'TShVzu_bjjuEUlC1ulTSvb4Qn0Y='
  pusherKey:  '64354707585286cfe58f'
  baseUrl:    'http://imdone.io'
  pusherChannelPrefix: 'private-imdoneio-dev'

module.exports = if /dev/i.test process.env.IMDONE_ENV then dev else prod

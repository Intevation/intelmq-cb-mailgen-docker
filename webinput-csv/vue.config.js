module.exports = {
  lintOnSave: "error",
  devServer: {
    public: 'localhost:1383',
    hotOnly: true,
    disableHostCheck: true,
    inline: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'X-Requested-With, content-type, Authorization'
    },
    proxy: {
      "/api": {
        target: "http://intelmq-webinput-csv-backend:8002"
      }
    }
  }
};

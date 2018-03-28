module.exports = {
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "localhost",
      port: 9545,   // truffle develop
      network_id: "*"
    }
  },
  mocha: {
    useColors: true
  }
};
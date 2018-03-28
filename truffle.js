module.exports = {
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "localhost",
      port: 9545,   // truffle develop
      network_id: "*"
    }
  },
  solc: { optimizer: { enabled: true, runs: 200 } },
  mocha: {
    useColors: true
  }
};
